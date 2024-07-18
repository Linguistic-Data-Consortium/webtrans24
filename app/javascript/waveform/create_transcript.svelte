<script>
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.3/src/getp.js'
    import parse_tsv from './parse_tsv'
    import parse_tdf from './parse_tdf'
    import parse_sad_with_aws from './parse_sad_with_aws'
    import { btn } from './buttons'
    import Spinner from './spinner.svelte'
    // import { update_segments2 } from './segments_helper'
    function update_segments2(){}
    import { add_timestamps2 } from './modification1'
    const parse_jsonn = (x) => JSON.parse(x);
    let ns = window.ldc.ns;
    let waveform = ns.waveform;
    export let data_set_id;
    export let data_set_file_name;
    export let auto = false;
    export let autox = true;
    let files;
    let text;
    let json;
    function retrieve(){
        console.log(data_set_id);
        console.log(data_set_file_name);
        if(data_set_id && data_set_file_name){
            // data_set_id = 3;
            let data_set_p = getp(`/data_sets/${data_set_id}?file_name=${data_set_file_name}`);
            data_set_p.then( (x) => {
                console.log(x);
                text = x.file;
                json = parse_tdf(text);
                add();
            } );
        }
    }
    export let tsv = false;
    export let tdf = false;
    export let sad_with_aws = false;
    let jsonn;
    function upload(){
        const r = new FileReader();
        let o = null;
        r.onload = function(e){
            text = e.target.result;
            if(text.match(/^file;unicode/)){
                tdf = text;
            }
            else if(text.match(/^\s*\[\s*\{/)){
                tdf = text;
            }
            else if(text.match(/^\s*\[\s*\{/)){
                jsonn = text;
            }
        }
        r.readAsText(files[0]);
    }
        // that.w.add_timestamps2 data
        // $('#browse_b').html 'working...'
        // ldc_annotate.add_callback ->
        //     $('.Root').show()
        //     $('#browse_b').hide()
    function add(){
        auto = false;
        setTimeout( () => update_segments2(json), 100 );
    }
    // update_segments2([ 
    //     {
    //         docid: 's3://coghealth/120630_20211115_143051_FTDc_CoreCog.wav',
    //         beg: 1.0,
    //         end: 2.0,
    //         text: 'yyx'
    //     },
    //     {
    //         docid: 's3://coghealth/120630_20211115_143051_FTDc_CoreCog.wav',
    //         beg: 3.0,
    //         end: 4.0,
    //         text: 'yz'
    //     }
    // ]);
    function add_save(){
        // add_off = true;
        auto = false;
        setTimeout( () => {
            add_timestamps2(json);
            ldc_annotate.add_callback( () => {
                window.location.reload();
            });
        }, 100 );
    }
    let index_segments_by_id;
    function create_segments(){
        const w = waveform;
        index_segments_by_id = new Map();
        // active = w.set_active_transcript_line null
        let active;
        if(w.segments){
            active = w.segments.get_active();
        }
        else{
            active = null;
        }
        // if active and $("##{active}").length
        //     aactive = String($("##{active}").data().iid)
        w.map = new Map();
        w.rmap = new Map();
        for(let c1 of json){
            index_segments_by_id.set(c1.id, c1);
            w.map.set(c1.id, `node-${c1.iid}`);
            w.rmap.set(`node-${c1.iid}`, c1.id);
            // # active = id if active is w.map[id]
            // aactive = id if (aactive is iid)
        }
        window.sources_object.add_source_audio_collision(w.wave_docid);
        w.update_underlines = true;
        // w.set_active_transcript_line aactive, true
        // console.log 'HERE'
        // console.log aactive
        // console.log that.index2
        // aactive
        return null;
    }
    if(data_set_file_name){
        retrieve();
    }
    if(auto) text = auto;
    let second_auto = true;
    // const createm = {
    //     name: 'create_transcript_modal',
    //     title: 'Create Transcript',
    //     h: '',
    //     buttons: [
    //         [ 'Save', btn, create ]
    //     ]
    // };
    let autoloading = false;
    if(ns.task_id == 77 || ns.task_id == 79){
        autoloading = true;
        autox = false;
        json = parse_sad_with_aws(text);
        add_save();
    }
</script>

<style>
    pre {
        width: 800px;
        overflow: auto;
    }
</style>

{#if autoloading}
    Loading Transcript
    <Spinner />
{/if}

{#if autox}
<div class="overflow-auto">
    <div class="Box-body overflow-auto">
        {#if data_set_id && data_set_file_name}
            <div><span>Adding transcript</span><span class="mx-auto w-8 h-8"><Spinner /></span></div>
        {:else}
            {#if !auto}
                <input type="file" bind:files>
            {/if}
            <div>
            {#if (files && files[0]) || auto}
                {#if json}
                    <button class="{btn}" on:click={add} data-close-dialog>Add Read Only</button>
                    {#if window.ldc.permissions.admin || auto}
                        <button class="{btn}" on:click={add_save} data-close-dialog>Add and Save</button>
                    {/if}
                {:else if text}
                    {#if tsv}
                        file appears to be TSV
                        <button class="{btn}" on:click={() => json = parse_tsv(text)}>parse as TSV</button>
                    {:else if tdf}
                        file appears to be TDF
                        <button class="{btn}" on:click={() => json = parse_tdf(text)}>parse as TDF</button>
                    {:else if sad_with_aws}
                        file appears to be JSON
                        <button class="{btn}" on:click={() => json = parse_sad_with_aws(text)}>parse as JSON</button>
                    {:else if jsonn}
                        file appears to be JSON
                        <button class="{btn}" on:click={() => json = parse_jsonn(text)}>parse as JSON</button>
                    {:else}
                        unknown format
                    {/if}
                {:else}
                    <button class="{btn}" on:click={upload}>upload</button>
                {/if}
            {/if}
            </div>
        {/if}
        {#if json}
            <pre class="h-48">
                {#each json as x}
                    {JSON.stringify(x) + "\n"}
                {/each}
            </pre>
        {:else if text}
            {#if tsv}
                <h5>Original, first 10 lines</h5>
                <pre>{text.split("\n").slice(0,9).join("\n")}</pre>
            {:else if tdf}
                <h5>Original, first 10 lines</h5>
                <pre>{text.split("\n").slice(0,9).join("\n")}</pre>
            {:else if jsonn}
                <h5>Original, first 1000 characters</h5>
                <pre>{text.substr(0,999)}</pre>
            {:else if sad_with_aws}
                <h5>Original, first 1000 characters</h5>
                <pre>{JSON.stringify(text).substr(0,999)}</pre>
            {/if}
        {/if}
    </div>
</div>
{/if}
