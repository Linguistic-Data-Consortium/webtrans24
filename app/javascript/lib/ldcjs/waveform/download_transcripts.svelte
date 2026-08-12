<script>
    import JSZip from 'jszip';
    import Modal from '../../../modal.svelte';
    import { create_transcript } from './download_transcript_helper';
    import { btn } from '../work/buttons';
    import Spinner from '../work/spinner.svelte';
    // export let segs;
    export let task_id;
    let text;
    let json;
    let include_headers = false;
    let filename;
    let url;
    let running = false;
    // Step by step record of the whole download, shown in the dialog. The end user
    // has no access to the rails log, so everything we learn has to surface here.
    const TAG = '[download-transcripts]';
    // Bump on every change to this component. Reported below next to the server's own
    // version so a stale javascript bundle is obvious rather than mysterious.
    const BUILD = '2026-08-12-diagnostics';
    let steps = [];
    let kit_report = [];
    let raw_diagnostics = null;
    let copied = false;

    function begin(name, detail){
        const s = { name, state: 'run', detail: detail || '', ms: null, t0: performance.now() };
        steps = [ ...steps, s ];
        console.log(`${TAG} -> ${name}`, detail || '');
        return s;
    }
    function finish(s, state, detail){
        s.state = state;
        s.ms = Math.round(performance.now() - s.t0);
        if(detail !== undefined) s.detail = detail;
        steps = steps;
        const line = `${TAG} ${state === 'ok' ? 'ok  ' : state === 'warn' ? 'warn' : 'FAIL'} ${s.name} (${s.ms}ms) ${s.detail}`;
        if(state === 'fail') console.error(line); else console.log(line);
    }
    function note(name, state, detail){
        finish(begin(name), state, detail);
    }
    function snippet(s, n = 300){
        if(!s) return '(empty)';
        const one = s.replace(/\s+/g, ' ').trim();
        return one.length > n ? one.slice(0, n) + ' ...' : one;
    }

    async function create(){
        if(running) return;
        running = true;
        steps = [];
        kit_report = [];
        raw_diagnostics = null;
        copied = false;
        text = '';
        if(url){ URL.revokeObjectURL(url); url = null; }
        const request_url = `/kits/all?task_id=${task_id}`;
        note('front end build', 'ok', `${BUILD} (task_id ${task_id})`);
        try {
            // 1. headers -- a missing csrf meta tag used to throw before the fetch even started
            let headers;
            const s_headers = begin('prepare request');
            try {
                const meta = document.querySelector('meta[name="csrf-token"]');
                if(!meta) throw new Error('no <meta name="csrf-token"> in the page');
                headers = {
                    'content-type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-Token': meta.content
                };
                finish(s_headers, 'ok', `GET ${request_url}`);
            } catch(e){
                finish(s_headers, 'fail', `${e.message}`);
                throw e;
            }

            // 2. the request itself
            let res;
            const s_req = begin('request server', request_url);
            try {
                res = await fetch(request_url, { headers, credentials: 'same-origin' });
                const ct = res.headers.get('content-type') || '(none)';
                const d = `HTTP ${res.status} ${res.statusText} | content-type ${ct}` +
                    (res.redirected ? ` | redirected to ${res.url}` : '');
                finish(s_req, res.ok ? 'ok' : 'fail', d);
                if(res.redirected){
                    note('redirect detected', 'warn', `server sent us to ${res.url} -- usually a login/permission redirect`);
                }
            } catch(e){
                finish(s_req, 'fail', `network error: ${e.message} (server unreachable, blocked, or the request was cancelled)`);
                throw e;
            }

            // 3. read the body, whatever it is -- an html error page tells us as much as json
            let body;
            const s_body = begin('read response body');
            try {
                body = await res.text();
                finish(s_body, 'ok', `${body.length} bytes`);
            } catch(e){
                finish(s_body, 'fail', e.message);
                throw e;
            }

            // 4. parse
            let payload;
            const s_parse = begin('parse json');
            try {
                payload = JSON.parse(body);
                finish(s_parse, 'ok', Array.isArray(payload) ? `array of ${payload.length}` : `object with keys: ${Object.keys(payload).join(', ')}`);
            } catch(e){
                finish(s_parse, 'fail', `not json (${e.message}). Body starts: ${snippet(body)}`);
                throw new Error('server did not return json');
            }

            // 5. server side steps, if this deploy has them
            let data;
            if(Array.isArray(payload)){
                data = payload;
                note('server diagnostics', 'warn', 'none in response -- the server is running an older build of kits#all');
            } else {
                data = payload.kits || [];
                raw_diagnostics = payload.diagnostics || null;
                if(raw_diagnostics){
                    note('server build', 'ok', raw_diagnostics.endpoint_version || '(older build, no version reported)');
                }
                if(raw_diagnostics && raw_diagnostics.steps){
                    for(const s of raw_diagnostics.steps){
                        const d = s.ok ? JSON.stringify(s.detail) : `${s.error}: ${s.message}`;
                        note(`server: ${s.step}`, s.ok ? 'ok' : 'fail', `${d} (${s.ms}ms)`);
                    }
                    kit_report = raw_diagnostics.kits || [];
                }
                if(payload.error){
                    note('server error', 'fail', `${payload.error.class}: ${payload.error.message}`);
                    console.error(TAG, 'server backtrace', payload.error.backtrace);
                    throw new Error(payload.error.message);
                }
            }
            if(!res.ok) throw new Error(`server returned HTTP ${res.status}`);

            // 6. what came back
            const s_shape = begin('inspect payload');
            if(!Array.isArray(data)){
                finish(s_shape, 'fail', `expected a list of kits, got ${typeof data}`);
                throw new Error('unexpected payload shape');
            }
            finish(s_shape, data.length ? 'ok' : 'fail',
                `${data.length} kit(s): ` + (data.map(k => `${k.kit_uid} (${(k.segments || []).length} segments)`).join(', ') || 'none'));
            if(!data.length) throw new Error('the server returned no kits for this task');

            const problems = kit_report.filter(k => !k.included);
            if(problems.length){
                note('kits not included', 'warn',
                    problems.map(k => `${k.uid}: ${k.note}`).join(' | '));
            }

            // 7. build one tsv per kit
            const zip = new JSZip();
            const folder = zip.folder('transcripts');
            const previews = [];
            let files = 0;
            for(const kit of data){
                const s_kit = begin(`transcript ${kit.kit_uid}`);
                try {
                    const segs = kit.segments || [];
                    const tsv = create_transcript(kit.kit_uid, include_speaker, include_section, include_headers, segs);
                    folder.file(`${kit.kit_uid}.tsv`, tsv);
                    files++;
                    previews.push(`=== ${kit.kit_uid}.tsv ===\n` + tsv);
                    const lines = tsv.split('\n').filter(l => l.length).length;
                    finish(s_kit, segs.length ? 'ok' : 'warn',
                        `${segs.length} segments -> ${lines} line(s), ${tsv.length} bytes` +
                        (segs.length ? '' : ' -- nothing to write for this kit'));
                } catch(e){
                    finish(s_kit, 'fail', `${e.message}`);
                    console.error(TAG, `transcript ${kit.kit_uid} failed`, e);
                }
            }
            text = previews.join('\n');

            // 8. zip it
            let blob;
            const s_zip = begin('build zip');
            try {
                if(!files) throw new Error('no transcript files were produced');
                blob = await zip.generateAsync({ type: 'blob' });
                finish(s_zip, 'ok', `${files} file(s), ${blob.size} bytes`);
            } catch(e){
                finish(s_zip, 'fail', e.message);
                throw e;
            }

            // 9. hand it to the browser
            const s_url = begin('create download link');
            try {
                url = URL.createObjectURL(blob);
                finish(s_url, 'ok', 'ready -- use the Download link above');
            } catch(e){
                finish(s_url, 'fail', e.message);
                throw e;
            }
        } catch(e){
            note('stopped', 'fail', e && e.message ? e.message : String(e));
            console.error(TAG, 'download failed', e);
        } finally {
            running = false;
        }
    }

    function report_text(){
        const lines = [
            `download transcripts diagnostics -- task_id ${task_id}`,
            `page ${location.href}`,
            ...steps.map(s => `[${s.state}] ${s.name}${s.ms == null ? '' : ` (${s.ms}ms)`}${s.detail ? ' -- ' + s.detail : ''}`)
        ];
        if(kit_report.length){
            lines.push('', 'kits:');
            for(const k of kit_report){
                lines.push(`  ${k.uid} state=${k.state} tree_id=${k.tree_id} annotation_nodes=${k.annotation_nodes} segment_rows=${k.segment_rows} returned=${k.segments_returned} included=${k.included}${k.note ? ' -- ' + k.note : ''}`);
            }
        }
        return lines.join('\n');
    }
    function copy_report(){
        const t = report_text();
        console.log(t);
        if(navigator.clipboard){
            navigator.clipboard.writeText(t).then(() => { copied = true; }, () => { copied = false; });
        }
    }

    let include_speaker = false;
    let include_section = false;
    const modal = {
        title: 'Download Transcript',
        buttons: [
            [ 'Save', btn, cancel ]
        ]
    };
    function cancel(){ }
</script>

<style>
    pre {
        width: 800px;
        overflow: auto;
    }
    .step {
        font-family: ui-monospace, monospace;
        font-size: 12px;
        white-space: pre-wrap;
        word-break: break-word;
    }
    .ok   { color: #1a7f37; }
    .warn { color: #9a6700; }
    .fail { color: #cf222e; }
    .run  { color: #57606a; }
</style>

<Modal {...modal}>
    <div slot=summary>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
    </div>
    <div slot=body>
        <div class="overflow-auto">
            <div class="Box-body overflow-auto">
                <div>
                    {#if running}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {/if}
                    <div class="form-group">
                        <div class="form-group-header">Filename (.zip will be appended)</div>
                        <div class="form-group-body">
                            <input
                                type=text
                                class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                                bind:value={filename}
                            />
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_headers}
                                />
                                Include Headers
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_speaker}
                                />
                                Include Speaker
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    type=checkbox
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    bind:checked={include_section}
                                />
                                Include Section
                            </label>
                        </div>
                    </div>
                </div>
                <!-- {#if json}
                    <button class="{btn}" on:click={add} data-close-dialog>add</button>
                {:else if text}
                    <button class="{btn}" on:click={download}>download</button>
                {/if} -->
                <div><button class="{btn}" on:click={create} disabled={running}>Create</button> a transcript file, which you can preview below
                {#if url}
                    <!-- svelte-ignore a11y-missing-attribute -->
                    and then <a href={url} download={(filename || 'transcripts') + '.zip'}>Download</a>
                {/if}

                {#if steps.length}
                    <h4>Progress</h4>
                    <div>
                        {#each steps as s}
                            <div class="step {s.state}">
                                {s.state === 'ok' ? 'OK  ' : s.state === 'warn' ? 'WARN' : s.state === 'fail' ? 'FAIL' : '... '}
                                {s.name}{s.ms == null ? '' : ` (${s.ms}ms)`}{s.detail ? ' — ' + s.detail : ''}
                            </div>
                        {/each}
                    </div>
                    <div class="mt-2">
                        <button class="{btn}" on:click={copy_report}>Copy diagnostics</button>
                        {#if copied}<span class="ok">copied to clipboard</span>{/if}
                    </div>
                {/if}

                {#if kit_report.length}
                    <h4>Kits</h4>
                    <div>
                        {#each kit_report as k}
                            <div class="step {k.included ? 'ok' : 'fail'}">
                                {k.uid} — state {k.state}, tree_id {k.tree_id}, {k.annotation_nodes} annotation node(s), {k.segment_rows} segment row(s) in db, {k.segments_returned} returned{k.note ? ' — ' + k.note : ''}
                            </div>
                        {/each}
                    </div>
                {/if}

                {#if raw_diagnostics}
                    <details class="mt-2">
                        <summary>Raw server diagnostics</summary>
                        <pre class="step">{JSON.stringify(raw_diagnostics, null, 2)}</pre>
                    </details>
                {/if}

                {#if json}
                    {#each json as x}
                        {JSON.stringify(x) + "\n"}
                    {/each}
                {:else if text}
                    <h4>Preview</h4>
                    <pre>{text}</pre>
                {/if}
            </div>
        </div>
    </div>
</Modal>
