<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn, dbtn } from "./buttons"
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import KitType from './kit_type.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { selectedff, response } from './helpers';
    /**
     * @typedef {Object} Props
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} help
     * @property {any} portal_manager
     */

    /** @type {Props} */
    let {
        admin = false,
        lead_annotator = false,
        help,
        portal_manager
    } = $props();
    let name = $state();
    let p = $state();
    function get(){ p = getp('/kit_types') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_kit_type_modal',
        title: 'Create Kit Type',
        h: '',
        buttons: [
            [ 'Save', btn, create ]
        ]
    };
    const deletem = {
        name: 'delete_kit_type_modal',
        title: 'Delete Kit Type',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    function create(){
        postp(
            "/kit_types",
            { name: name }
        ).then(response).then(get);
    }
    function destroy(){
        deletep(
            `/kit_types/${kit_type_id}`
        ).then(response).then(get);
    }
    let kit_type_id = $state({});
    let kit_type_index = $state({});
    let pp = $state();
    function open(){
        pp = getp(`/kit_types/${kit_type_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // kit_type_id = 57;
    //     kit_type_id = 33;
    //     open()
    // }, 1000)
    let style = $state();
    let selectedf = selectedff(x => style = x);
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to kit type list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <KitType {admin} {lead_annotator} {kit_type_id} {...v} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All Kit Types</div>
            {#if kit_type_id}
                <div>
                    <button class="{btn}" onclick={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class="{btn}" onclick={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        {#snippet summary()}
                        <div >
                            Delete
                        </div>
                        {/snippet}
                        {#snippet body()}
                        <div >
                            This will delete the kit type {kit_type_index[kit_type_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                     <div >
                        Create Kit Type
                     </div>
                     {/snippet}
                    {#snippet body()}
                     <div >
                       <form onsubmit={preventDefault(()=>null)}>
                            <InputText label=Name key=name bind:value={name} />
                        </form>
                     </div>
                     {/snippet}
                </Modal>
            {/if}
        </div>
        <Table bind:selected={kit_type_id} indexf={x => kit_type_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
