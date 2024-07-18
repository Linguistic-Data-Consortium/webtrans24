<script>
    import { tick } from 'svelte';
    import { get_projects, get_project, create_project, delete_project } from './controllers'
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Flash from './flash.svelte'
    import Project from './project.svelte'
    import InputText from './input_text.svelte'
    import { btn, cbtn, dbtn } from './buttons'
    import Spinner from './spinner.svelte'
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    export let goto_project;
    export let goto_task;
    let name;
    let p;
    export let session = null;
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
                project_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
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
    let project_id;
    let project_index;
    let pp;
    function open(){
        pp = get_project(project_id, session);
    }
    let info = false;
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
    let style;
    let timeout;
    function selected(e){
        style = `position: absolute; left: ${e.detail.pageX-20}px; top: ${e.detail.pageY+20}px; z-index: 10`;
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style = null, 2000);
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>Projects contain Tasks, which in turn contain Kits</p>
        <p>Select and Open a Project from the table</p>
        {#if lead_annotator}
            <p>You also have permission to create a new Project</p>
        {/if}
    </div>
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class={btn} on:click={back}>Return to project list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Project {help} {admin} {lead_annotator} {project_id} {...v} on:reload={reload} on:reload2 {goto_task} {info} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around items-center my-2">
            {#if lead_annotator}
                <div class="font-semibold">All Projects</div>
            {:else}
                <div class="font-semibold">My Projects</div>
            {/if}
            {#if project_id && project_index}
                <div>
                    <button class={cbtn} on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class={btn} on:click={openi}>Open Project Info</button></div>
                        <div><button class={btn} on:click={open}>Open Task List</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the project {project_index[project_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
            {:else}
                <div>Select a Project in the table for more options.</div>
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    <div slot=summary>
                        Create Project
                    </div>
                    <div slot=body>
                        <form on:submit|preventDefault={()=>null}>
                            <InputText label=Name key=name bind:value={name} />
                       </form>
                    </div>
                </Modal>
            {/if}
        </div>
        <Table bind:selected={project_id} bind:index={project_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
