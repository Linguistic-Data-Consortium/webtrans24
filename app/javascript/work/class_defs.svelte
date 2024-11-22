<script>
    import { btn } from "./buttons"
    import { getp, postp, deletep } from '../lib/ldcjs/getp';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Spinner from './spinner.svelte'
    import { toast } from "svelte-sonner";
    /**
     * @typedef {Object} Props
     * @property {boolean} [help]
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {boolean} [portal_manager]
     */

    /** @type {Props} */
    let {
        help = false,
        admin = false,
        lead_annotator = false,
        portal_manager = false
    } = $props();
    const unused = help && portal_manager;
    let name;
    let p = $state();
    function get(){ p = getp('/class_defs') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_class_def_modal',
        title: 'Create Namespace',
        h: ''
    };
    const deletem = {
        name: 'delete_class_def_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete Namespace',
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
            }
            else{
                flash_value = "created " + data.class_def.name;
            }
            toast.success(flash_value);
            get();
        }
    }
    function create(){
        postp(
            "/class_defs",
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/class_defs/${class_def_id}`
        ).then(response);
    }
    let class_def_id = $state();
    let class_def_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/class_defs/${class_def_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // class_def_id = 57;
    //     class_def_id = 33;
    //     open()
    // }, 1000)
    function reload(e){
        open();
    }
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to namespace list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            ClassDef
            <!-- <ClassDef {admin} {lead_annotator} {class_def_id} {...v} /> -->
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All Namespaces</div>
            {#if class_def_id}
                <div>
                    <button class="{btn}" onclick={open}>Open</button>
                </div>
                {#if admin}
                    <!-- <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the kit type {class_def_index[class_def_id].name}, are you sure you want to do this?
                        </div>
                    </Modal> -->
                {/if}
            {/if}
            {#if lead_annotator}
                <!-- <Modal {...createm}>
                    <div slot=summary>
                        Create Namespace
                    </div>
                    <div slot=body>
                        <form>
                            <label>
                                Name
                                <input type=text bind:value={name}/>
                            </label>
                        </form>
                    </div>
                    <div slot=footer>
                        <button type="button" class="{btn}" data-close-dialog on:click={create}>Save</button>
                    </div>
                </Modal> -->
            {/if}
        </div>
        <Table bind:selected={class_def_id} indexf={x => class_def_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 />
    {/if}
{/await}
