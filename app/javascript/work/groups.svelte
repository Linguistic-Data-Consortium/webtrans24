<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Group from './group.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    // export let portal_manager = false;
    // export let project_manager = false;
    let name;
    let p;
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
    let flash_type = null;
    let flash_value;
    function response(data){
        if(data.error){
            flash_type = 'error';
            flash_value = data.error.join(' ');
        }
        else{
            flash_type = 'success';
            if(data.deleted){
                flash_value = data.deleted;
                group_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
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
    let group_id;
    let group_index;
    let pp;
    function open(){
        pp = getp(`/groups/${group_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    let style;
    let timeout;
    function selected(e){
        style = `position: absolute; left: ${e.detail.pageX-20}px; top: ${e.detail.pageY+20}px; z-index: 10`;
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style = null, 2000);
    }
    function reload(e){
        open();
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>groups</p>
    </div>
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" on:click={back}>Return to Group list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Group {help} {admin} {lead_annotator} {group_id} {...v} on:reload={reload} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All groups</div>
            {#if group_id && group_index}
                <div>
                    <button class="{btn}" on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class="{btn}" on:click={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the group {group_index[group_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                Select a group in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create group
                    </div>
                    <div slot=body>
                         <form on:submit|preventDefault={()=>null}>
                             <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={group_id} bind:index={group_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
