<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn } from "./buttons"
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from './modall.svelte'
    import Workflow from './workflow.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { selectedff } from './helpers';
    import { toast } from "svelte-sonner";
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     */

    /** @type {Props} */
    let { help, admin = false, lead_annotator = false } = $props();
    let category;
    let name = $state();
    let p = $state();
    function get(){ p = getp('/workflows') }
    get();
    let columns = [
        [ 'Name', 'name', 'col-1' ],
        [ 'Description', 'description', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
    ];
    const createm = {
        name: 'create_workflow_modal',
        title: 'Create workflow',
        h: ''
    };
    const deletem = {
        name: 'delete_workflow_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete workflow',
        h: ''
    };
    function response(data){
        let flash_value;
        if(!data){
            toast.error('bad response');
        }
        else if(data.error){
            flash_value = data.error.join(' ');
            toast.error(flash_value);
        }
        else{
            if(data.deleted){
                flash_value = data.deleted;
                workflow_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            toast.success(flash_value);
            get();
        }
    }
    function create(){
        postp(
            "/workflows",
            { category: category, name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/workflows/${workflow_id}`
        ).then(response);
    }
    let workflow_id = $state();
    let workflow_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/workflows/${workflow_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    let style = $state();
    let selectedf = selectedff(x => style = x);
</script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>workflows</p>
    </div>
    {/snippet}
</Help>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to Workflow list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Workflow {help} {admin} {lead_annotator} {workflow_id} {...v} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All workflows</div>
            {#if workflow_id && workflow_index}
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
                            This will delete the workflow {workflow_index[workflow_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                Select a workflow in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create workflow
                    </div>
                    {/snippet}
                    {#snippet body()}
                    <div>
                        <form onsubmit={preventDefault(()=>null)}>
                             <InputText label=Name key=name bind:value={name} />
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
        <Table bind:selected={workflow_id} indexf={x => workflow_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
