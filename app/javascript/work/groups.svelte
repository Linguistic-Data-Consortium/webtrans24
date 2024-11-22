<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep } from '../lib/ldcjs/getp';
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Group from './group.svelte'
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
    // export let portal_manager = false;
    // export let project_manager = false;
    let name = $state();
    let p = $state();
    function get(){ p = getp('/groups') }
    get();
    let columns = [
        [ 'Name', 'name', 'col-1' ],
        [ 'Description', 'description', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
    ];
    const createm = {
        name: 'create_group_modal',
        title: 'Create group',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_group_modal',
        title: 'Delete group',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
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
                group_id = null;
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
            "/groups",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/groups/${group_id}`
        ).then(response);
    }
    let group_id = $state();
    let group_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/groups/${group_id}`)
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
        <p>groups</p>
    </div>
    {/snippet}
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to Group list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Group {help} {admin} {lead_annotator} {group_id} {...v} reload={open} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All groups</div>
            {#if group_id && group_index}
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
                        <div >
                            This will delete the group {group_index[group_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                Select a group in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create group
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
        <Table bind:selected={group_id} indexf={x => group_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
