<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn, cbtn } from "./buttons"
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import DataSet from './data_set.svelte'
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
    let name = $state();
    let p = $state();
    function get(){ p = getp('/data_sets') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Data Set', 'name', 'col-1' ],
        [ 'Spec', 'spec', 'col-1' ],
        [ 'Description', 'description', 'col-8' ]
    ];
    const createm = {
        name: 'create_data_set_modal',
        title: 'Create data_set',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_data_set_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete data_set',
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
                data_set_id = null;
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
            "/data_sets",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/data_sets/${data_set_id}`
        ).then(response);
    }
    let data_set_id = $state();
    let data_set_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/data_sets/${data_set_id}`)
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
        <p>data_sets</p>
    </div>
    {/snippet}
</Help>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to Feature list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <DataSet {help} {admin} {lead_annotator} {data_set_id} {...v} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All data_sets</div>
            {#if data_set_id && data_set_index}
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
                            This will delete the data_set {data_set_index[data_set_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                Select a data_set in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create data_set
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
        <Table bind:selected={data_set_id} indexf={x => data_set_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf}/>
    {/if}
{/await}
