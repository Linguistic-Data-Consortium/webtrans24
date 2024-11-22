<script>
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from './modall.svelte'
    import XlassDef from './xlass_def.svelte'
    import { btn1, cbtn, dbtn } from './buttons'
    import { fi_text } from './form_inputs';
    import { selectedff, response } from './helpers';
    /**
     * @typedef {Object} Props
     * @property {boolean} [admin]
     * @property {boolean} [help]
     * @property {boolean} [lead_annotator]
     * @property {boolean} [portal_manager]
     */

    /** @type {Props} */
    let {
        admin = false,
        help = false,
        lead_annotator = false,
        portal_manager = false
    } = $props();
    const unused = portal_manager && help;
    let name = $state();
    let p = $state();
    function get(){ p = getp('/xamespaces') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    function create(){
        postp(
            "/xamespaces",
            { name: name }
        ).then(response).then(get);
        cdialog.close();
    }
    function destroy(){
        deletep(
            `/xamespaces/${class_def_id}`
        ).then(response).then(get);
        ddialog.close();
    }
    let class_def_id = $state();
    let class_def_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/xamespaces/${class_def_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // class_def_id = 57;
    //     class_def_id = 561;
    //     open()
    // }, 1000)
    function reload(e){
        open();
    }
    let style = $state();
    let selectedf = selectedff(x => style = x);
    p.then( (x) => console.log(x))
    let cdialog = $state();
    let ddialog = $state();
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class={btn1} onclick={back}>Return to namespace list</button>
        </div>
        {#await pp}
            <div><span>Loading</span><span class="AnimatedEllipsis"></span></div>
        {:then v}
            <XlassDef {admin} {lead_annotator} {class_def_id} {...v} on:reload={reload} />
        {/await}
    {:else}
        <div class="flex justify-around items-center my-3">
            <div class="font-semibold">All Namespaces</div>
            {#if class_def_id}
                <div>
                    <button class={cbtn} onclick={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class={cbtn} onclick={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <button class="{dbtn}" onclick={() => ddialog.showModal()}>Delete Namespace</button>
                    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
                    <dialog bind:this={ddialog} onclick={(e) => e.target.tagName == 'DIALOG' && ddialog.close()} onkeypress={() => null}>
                        <div>Delete Namespace</div>
                        <div>This will delete the class_def {class_def_index[class_def_id].name}, are you sure you want to do this?</div>
                        <div class="flex mt-3">
                            <button class="{btn1} mr-3" onclick={() => ddialog.close()}>Cancel</button>
                            <button class="{dbtn}" onclick={destroy}>Delete</button>
                        </div>
                    </dialog>
                {/if}
            {/if}
            {#if lead_annotator}
                <button class="{cbtn}" onclick={() => cdialog.showModal()}>Create Namespace</button>
                <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
                <dialog bind:this={cdialog} onclick={(e) => e.target.tagName == 'DIALOG' && cdialog.close()} onkeypress={() => null}>
                    <div>Create Namespace</div>
                    <div>Name</div>
                    <div><input type="text" class="{fi_text}" bind:value={name}/></div>
                    <div class="flex mt-3">
                        <button class="{btn1} mr-3" onclick={() => cdialog.close()}>Cancel</button>
                        <button class="{cbtn}" onclick={create}>Save</button>
                    </div>
                </dialog>
            {/if}
        </div>
        <Table bind:selected={class_def_id} indexf={x => class_def_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
