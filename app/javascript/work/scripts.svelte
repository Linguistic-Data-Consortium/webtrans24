<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn, cbtn, dbtn } from "./buttons"
    import { tick } from 'svelte';
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Script from './script.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { selectedff } from './helpers';
    let unused = portal_manager;
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [portal_manager]
     * @property {boolean} [project_manager]
     */

    /** @type {Props} */
    let {
        help,
        admin = false,
        portal_manager = false,
        project_manager = false
    } = $props();
    let category;
    let name = $state();
    let p = $state();
    function get(){ p = getp('/scripts') }
    get();
    let columns = [
        [ 'Name', 'name', 'col-1' ],
        [ 'Description', 'description', 'col-1' ],
        [ 'Type', 'type', 'col-1' ],
    ];
    const createm = {
        name: 'create_script_modal',
        title: 'Create script',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_script_modal',
        title: 'Delete script',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    let flash_type = $state(null);
    let flash_value = $state();
    function response(data){
        if(data.error){
            flash_type = 'error';
            flash_value = data.error.join(' ');
        }
        else{
            flash_type = 'success';
            if(data.deleted){
                flash_value = data.deleted;
                script_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/scripts",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/scripts/${script_id}`
        ).then(response);
    }
    let script_id = $state();
    let script_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/scripts/${script_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    let style = $state();
    let selectedf = selectedff(x => style = x);
    tick().then(()=>{
        // project_id = 57;
        // project_id = 33;
        // script_id = 1;
        // open();
        
    });
</script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>scripts</p>
    </div>
    {/snippet}
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to Script list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Script {help} {admin} {project_manager} {script_id} {...v} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around">
            <div>All scripts</div>
            {#if script_id && script_index}
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
                            This will delete the script {script_index[script_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                Select a script in the table for more options.
            {/if}
            {#if project_manager}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create script
                    </div>
                    {/snippet}
                    {#snippet body()}
                    <div>
                        <form onsubmit={preventDefault(()=>null)}>
                            <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                    {/snippet}
                </Modal>
            {/if}
        </div>
        <Table bind:selected={script_id} indexf={x => script_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
