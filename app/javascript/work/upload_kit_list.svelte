<script>
    import { run } from 'svelte/legacy';

    import { postp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Modal from '../modal.svelte'
    import { btn } from './buttons'
    const parse_jsonn = (x) => JSON.parse(x);
    let { task_id, reload2 } = $props();
    let files = $state();
    let text = $state();
    let json = $state();
    function parse_kits(){
        const j = [];
        for(let x of text.split("\n")){
            if(x.length) j.push( { docid: x } );
        }
        return j;
    }
    let tdf = $state();
    let jsonn;
    function upload(){
        const r = new FileReader();
        let o = null;
        r.onload = function(e){
            text = e.target.result;
            if(text.match(/^\S+\n/)){
                tdf = text;
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
        const j = { task_id: task_id, kits: json };
        postp('/create_kits_from_kits_tab', j).then( (data) => {
            console.log(data);
            reload2();
        });
    }
    let name;
    let typed = $state();
    run(() => {
        text = typed;
    });
    run(() => {
        tdf = typed;
    });
    const modal = {
        title: 'Create Kits',
        buttons: []
    };
    function cancel(){ }
</script>

<style>
    pre {
        width: 800px;
        overflow: auto;
    }
    #messagee {
        position: absolute;
        top: 50px;
        left: 300px;
        font-size: 24px;
    }
</style>

<Modal {...modal}>
    {#snippet summary()}
    <div>
        Create Kits
    </div>
    {/snippet}
    {#snippet body()}
    <div>
        <div class="overflow-auto">
            <div class="Box-body overflow-auto">
                <div>type here, or upload a file</div>
                <div>
                    <textarea
                      bind:value={typed}
                      class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                    ></textarea>
                </div>
                <div>
                    <input
                      type="file"
                      bind:files
                      class="focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                    >
                </div>
            <div>
                {#if (files && files[0]) || typed}
                    {#if json}
                        <button class="{btn}" onclick={add} data-close-dialog>Create Kits</button>
                    {:else if text}
                        {#if tdf}
                            file appears to be docids
                            <button class="{btn}" onclick={() => json = parse_kits(text)}>parse as text</button>
                        {:else if jsonn}
                            file appears to be JSON
                            <button class="{btn}" onclick={() => json = parse_jsonn(text)}>parse as JSON</button>
                        {:else}
                            unknown format
                        {/if}
                    {:else}
                        <button class="{btn}" onclick={upload}>upload</button>
                    {/if}
                {/if}
                </div>
                {#if json}
                    <pre>
                        {#each json as x}
                            {JSON.stringify(x) + "\n"}
                        {/each}
                    </pre>
                {:else if text}
                    {#if tdf}
                        <h5>Original, first 10 lines</h5>
                        <pre>{text.split("\n").slice(0,9).join("\n")}</pre>
                    {:else if jsonn}
                        <h5>Original, first 1000 characters</h5>
                        <pre>{text.substr(0,999)}</pre>
                    {/if}
                {/if}
            </div>
        </div>
    </div>
    {/snippet}
</Modal>
