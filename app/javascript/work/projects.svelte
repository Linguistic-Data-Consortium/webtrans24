<script>
    import { preventDefault } from 'svelte/legacy';

    import { tick } from 'svelte';
    import { get_projects, get_project, create_project, delete_project } from './controllers'
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Project from './project.svelte'
    import InputText from './input_text.svelte'
    import { btn, cbtn, dbtn } from './buttons'
    import Spinner from './spinner.svelte'
    import { selectedff } from './helpers';
    import { toast } from "svelte-sonner";
    let name = $state();
    let p = $state();
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} goto_project
     * @property {any} goto_task
     * @property {any} [session]
     */

    /** @type {Props} */
    let {
        help,
        admin = false,
        lead_annotator = false,
        goto_project,
        goto_task,
        session = null,
        reload2
    } = $props();
    function get(){ p = get_projects(session) }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Project', 'name', 'col-2', 'html' ],
        [ 'Task Count', 'task_count', 'col-1' ]
    ];
    const createm = {
        name: 'create_project_modal',
        title: 'Create Project',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_project_modal',
        title: 'Delete Project',
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
                project_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            toast.success(flash_value);
            get();
        }
    }
    function create(){
        create_project(
            { name: name }, session
        ).then(response);
    }
    function destroy(){
        delete_project(
            project_id, session
        ).then(response);
    }
    let project_id = $state();
    let project_index = $state();
    let pp = $state();
    function open(){
        pp = get_project(project_id, session);
    }
    let info = $state(false);
    function openi(){
        info = true;
        open();
    }
    function back(){
        pp = null;
        get();
    }
    if(goto_project){
        // setTimeout(()=>{
        //     // project_id = 57;
        //     // project_id = 33;
        //     project_id = goto_project;
        //     open();
        // }, 1000)
        tick().then(()=>{
            // project_id = 57;
            // project_id = 33;
            project_id = goto_project;
            open();
        });
    }
    function reload(e){
        open();
    }
    let style = $state();
    let selectedfff = selectedff(x => style = x);
    function selectedf(e, k){
        selectedfff(k);
        project_id = e;
    }
</script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>Projects contain Tasks, which in turn contain Kits</p>
        <p>Select and Open a Project from the table</p>
        {#if lead_annotator}
            <p>You also have permission to create a new Project</p>
        {/if}
    </div>
    {/snippet}
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class={btn} onclick={back}>Return to project list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Project {help} {admin} {lead_annotator} {project_id} {...v} {reload} {reload2} {goto_task} {info} />
        {/await}
    {:else}
        <div class="flex justify-around items-center my-2">
            {#if lead_annotator}
                <div class="font-semibold">All Projects</div>
            {:else}
                <div class="font-semibold">My Projects</div>
            {/if}
            {#if project_id && project_index}
                <div>
                    <button class={cbtn} onclick={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class={btn} onclick={openi}>Open Project Info</button></div>
                        <div><button class={btn} onclick={open}>Open Task List</button></div>
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
                        <div>
                            This will delete the project {project_index[project_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                <div>Select a Project in the table for more options.</div>
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div >
                        Create Project
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
        <Table bind:selected={project_id} indexf={x => project_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
