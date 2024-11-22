<script>
    import { preventDefault } from 'svelte/legacy';

    import { tick } from 'svelte';
    import { get_task, create_task, delete_task } from './controllers'
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte';
    import Task from './task.svelte';
    import InputText from './input_text.svelte';
    import Spinner from './spinner.svelte';
    import { btn, cbtn, dbtn } from './buttons';
    import { selectedff, response } from './helpers';
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {any} project_id
     * @property {boolean} [project_admin]
     * @property {any} tasks
     * @property {any} project_users
     * @property {any} goto_task
     * @property {any} reload
     */

    /** @type {Props} */
    let {
        help,
        project_id,
        project_admin = false,
        tasks,
        project_users,
        goto_task,
        reload
    } = $props();
    let name = $state();
    // let p;
    // function get(){ p = getp('/tasks') }
    // get();
    
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Task', 'name', 'col-2' ],
        [ 'Available Kits', 'available_kit_count', 'col-1' ],
        [ 'Source UID', 'source_uid', 'col-1' ]
    ];
    const createm = {
        name: 'create_task_modal',
        title: 'Create Task',
        h: '',
        buttons: [
            [ 'Save', btn, create ]
        ]
    };
    const deletem = {
        name: 'delete_task_modal',
        title: 'Delete Task',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    function create(){
        create_task(project_id, { name: name }).then(response).then(reload);
    }
    function destroy(){
        delete_task(project_id, task_id).then(response).then(reload);
    }
    let task_id = $state();
    let task_index = $state();
    let pp = $state();
    function open(){
        pp = get_task(project_id, task_id);
    }
    let info = $state(false);
    function openi(){
        info = true;
        open();
    }
    function back(){
        pp = null;
    }
    if(goto_task){
        tick().then(() => {
            // task_id = 1766;
            task_id = goto_task;
            open()
        });
    }
    let style = $state();
    let selectedfff = selectedff(x => style = x);
    function selectedf(e, k){
        selectedfff(k);
        task_id = e;
    }
 </script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>Tasks contain Kits</p>
        <p>Select and Open a Task from the table</p>
        {#if project_admin}
            <p>You also have permission to create a new Task</p>
        {/if}
    </div>
    {/snippet}
</Help>

{#if false}
    loading...
{:else}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to task list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            {#if v.error}
                <div>Error: {v.error}</div>
            {:else}
                <div class="float-right p-2">
                    {v.name} {task_id}
                </div>
                <Task {help} {project_admin} {project_id} {task_id} {...v} {project_users} reload={open} {info} />
                <!-- {task_id} {task_index[task_id].name} -->
            {/if}
        {/await}
    {:else}
        <div class="flex justify-around items-center my-2">
            {#if project_admin}
                <div class="font-semibold">All Tasks</div>
            {:else}
                <div class="font-semibold">My Tasks</div>
            {/if}
            {#if task_id}
                <div>
                    <button class={cbtn} onclick={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div class="p-1"><button class="{btn}" onclick={openi}>Open Task Info</button></div>
                        <div class="p-1"><button class="{btn}" onclick={open}>Open Kit List</button></div>
                    </div>
                {/if}
                {#if project_admin}
                    <Modal {...deletem}>
                        {#snippet summary()}
                        <div>
                            Delete
                        </div>
                        {/snippet}
                        {#snippet body()}
                        <div>
                            This will delete the task {task_index[task_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {/if}
            {#if project_admin}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create Task
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
        <Table indexf={x => task_index = x} {columns} rows={tasks} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/if}
