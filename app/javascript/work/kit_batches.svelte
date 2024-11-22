<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn } from "./buttons"
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from './modall.svelte'
    import KitBatch from './kit_batch.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { selectedff, response } from './helpers';
    /**
     * @typedef {Object} Props
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {boolean} [portal_manager]
     * @property {boolean} [project_manager]
     */

    /** @type {Props} */
    let {
        admin = false,
        lead_annotator = false,
        portal_manager = false,
        project_manager = true
    } = $props();
    let unused = portal_manager;
    let name = $state();
    let p = $state();
    function get(){ p = getp('/kit_batches') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_kit_batch_modal',
        title: 'Create Kit Batch',
        h: ''
    };
    const deletem = {
        name: 'delete_kit_batch_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete Kit Batch',
        h: ''
    };
    function create(){
        postp(
            "/kit_batches",
            { name: name }
        ).then(response).then(get);
    }
    function destroy(){
        deletep(
            `/kit_batches/${kit_batch_id}`
        ).then(response).then(get);
    }
    let kit_batch_id = $state();
    let kit_batch_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/kit_batches/${kit_batch_id}`)
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
    function reload(e){
        open();
    }
    let style = $state();
    let selectedf = selectedff(x => style = x);
    let role;
    let project_id = $state();
    let task_id = $state();
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {JSON.stringify(v)}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to kit batch list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <KitBatch {admin} {lead_annotator} {kit_batch_id} {...v} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All Kit Batches</div>
            {#if kit_batch_id}
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
                        <div>
                            Delete
                        </div>
                        {/snippet}
                        {#snippet body()}
                        <div>
                            This will delete the kit batch {kit_batch_index[kit_batch_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create Kit Batch
                    </div>
                    {/snippet}
                    {#snippet body()}
                    <div>
                        <form onsubmit={preventDefault(()=>null)}>
                            <InputText label=Name key=name bind:value={name} />
                           {#if project_manager}
                               <div class="pt-2">
                                   <div>If you want to automatically add the invitee to</div>
                                   <div>a project and/or task, select those here.</div>
                               </div>
                               {#await p}
                                   loading...
                               {:then v}
                                   <div>
                                       <label for=x>Project</label>
                                       <select id=x class="form-select" bind:value={project_id}>
                                           <option value={null}></option>
                                           {#each v.projects as project}
                                               <option value={project.id}>
                                                   {project.name}
                                               </option>
                                           {/each}
                                       </select>
                                   </div>
                                   <div>
                                       {#if project_id}
                                           <label for=y>Task</label>
                                           <select id=y class="form-select" bind:value={task_id}>
                                               <option value={null}></option>
                                               {#each v.tasks_index[project_id] as task}
                                                   <option value={task.id}>
                                                       {task.name}
                                                   </option>
                                               {/each}
                                           </select>
                                       {/if}
                                   </div>
                               {/await}
                           {/if}
                           <!-- <select class="form-select" aria-label="Important decision">
                               <option>Select</option>
                               <option value="option 2">Option 2</option>
                             </select> -->
                       </form>
                    </div>
                    {/snippet}
                    {#snippet footer()}
                    <div>
                        <button type="button" class="{btn}"   data-close-dialog onclick={create}>Save</button>
                    </div>
                    {/snippet}
                </Modal>
            {/if}
        </div>
        <Table bind:selected={kit_batch_id} indexf={x => kit_batch_index = x} {columns} rows={v.kit_batches} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
