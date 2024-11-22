<script>
    import { postp, deletep } from '../lib/ldcjs/getp';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    import { ok_reload } from './helpers';
    
    export const help = false;
    /**
     * @typedef {Object} Props
     * @property {any} group_id - export let project_id;
     * @property {any} group_users
     * @property {any} reload
     */

    /** @type {Props} */
    let { group_id, group_users, reload } = $props();
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
    ];
    const createm = {
        name: 'create_group_user_modal',
        title: 'Add Member',
        h: ''
    };
    const deletem = {
        name: 'delete_group_user_modal',
        title: 'Remove Member',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    function create(){
        postp(
            `/group_users`,
            { group_id: group_id, user_id: user_id }
        ).then(x => ok_reload(x, reload));
    }
    function destroy(){
        deletep(
            `/group_users/${group_user_id}`
        ).then(x => ok_reload(x, reload));
    }
    let group_user_id = $state();
    let group_user_index = $state();
    let name;
    let user_id;
    let pp;
    // $: pp = getp(`/projects/${project_id}/users_not_in_project?term=${name}`)
    function back(){
        pp = null;
    }
    const urlf = (name) => `/groups/${group_id}/users_not_in?term=${name}`;
    function auto2(x){
        user_id = x.id;
        create();
    }
    const group_admin = true;
    let timeout;
</script>

<style>
</style>

<div class="flex justify-around">
    <div>Members</div>
    {#if group_user_id}
        {#if group_admin}
            <Modal {...deletem}>
                {#snippet summary()}
                <div >
                    Remove User
                </div>
                {/snippet}
                {#snippet body()}
                <div >
                    This will remove {group_user_index[group_user_id].name}, are you sure you want to do this?
                </div>
                {/snippet}
            </Modal>
        {/if}
    {/if}
    {#if group_admin}
        <SelectUsers {urlf} {create} {auto2} />
    {/if}
</div>
<div class="flex justify-around p-6">
    <div class="float-left col-6">
        <Table bind:selected={group_user_id} indexf={x => group_user_index = x} {columns} rows={group_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6 p-6">
    </div>
</div>
