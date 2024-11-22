<script>
    import { run } from 'svelte/legacy';
    import { postp, deletep } from '../lib/ldcjs/getp';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import TaskUser from './task_user.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    import { ok_reload } from './helpers';
    export const help = false;
    /**
     * @typedef {Object} Props
     * @property {any} project_id
     * @property {any} task_id
     * @property {boolean} [task_admin]
     * @property {any} task_users
     * @property {any} project_users
     * @property {any} reload
     */

    /** @type {Props} */
    let {
        project_id,
        task_id,
        task_admin = false,
        task_users,
        project_users,
        reload
    } = $props();
    let unused = project_id;
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ],
        [ 'State', 'state', 'col-1' ],
        [ 'Admin', 'admin', 'col-1 ']
    ];
    const deletem = {
        name: 'delete_task_user_modal',
        title: 'Remove Member',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    function create(){
        postp(
            `/task_users`,
            { task_id: task_id, user_id: user_id }
        ).then(x => ok_reload(x, reload));
    }
    function destroy(){
        deletep(
            `/task_users/${task_user_id}`
        ).then(x => ok_reload(x, reload));
    }
    let task_user_id = $state();
    let task_user_index = $state();
    let user_id;
    function auto2(x){
        user_id = x.user_id;
        create();
    }
    let is_admin = $state();
    run(() => {
        if(task_user_id){
            is_admin = task_user_index[task_user_id].admin;
        }
    });
</script>

<style>
</style>

<div class="flex justify-around">
    <div>Members</div>
    {#if task_user_id}
        {#if task_admin}
            <Modal {...deletem}>
                {#snippet summary()}
                <div>
                    Remove User
                </div>
                {/snippet}
                {#snippet body()}
                <div>
                    This will remove {task_user_index[task_user_id].name}, are you sure you want to do this?
                </div>
                {/snippet}
            </Modal>
        {/if}
    {/if}
    {#if task_admin}
        <SelectUsers urlf={project_users} {create} {auto2} />
    {/if}
</div>
<div class="flex">
    <div class="w-1/2 col-{task_user_id ? '6' : '12'}">
        <Table bind:selected={task_user_id} indexf={x => task_user_index = x} {columns} rows={task_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6 p-6">
        {#if task_user_id && task_admin}
            {#each task_users as x}
                {#if x.id == task_user_id}
                    <TaskUser id={x.id} is_admin={x.admin} xstate={x.state} {reload} />
                {/if}
            {/each}
        {/if}
    </div>
</div>
