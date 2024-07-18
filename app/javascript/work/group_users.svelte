<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    // export let project_id;
    export let group_id;
    export let group_users;
    export const help = false;
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
            }
            else{
                flash_value = data.ok;
            }
            setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    function create(){
        postp(
            `/group_users`,
            { group_id: group_id, user_id: user_id }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/group_users/${group_user_id}`
        ).then(response);
    }
    let group_user_id;
    let group_user_index;
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

{#if flash_type}
    <div class="text-center flash flash-{flash_type} mb-3">
        {flash_value}
        <button type=button class="close flash-close js-flash-close">
            <i class="fa fa-times"></i>
        </button>
    </div>
{/if}
<div class="flex justify-around">
    <div>Members</div>
    {#if group_user_id}
        {#if group_admin}
            <Modal {...deletem}>
                <div slot=summary>
                    Remove User
                </div>
                <div slot=body>
                    This will remove {group_user_index[group_user_id].name}, are you sure you want to do this?
                </div>
            </Modal>
        {/if}
    {/if}
    {#if group_admin}
        <SelectUsers {urlf} {create} {auto2} />
    {/if}
</div>
<div class="flex justify-around p-6">
    <div class="float-left col-6">
        <Table bind:selected={group_user_id} bind:index={group_user_index} {columns} rows={group_users} use_filter={true} key_column=id height=400 />
    </div>
    <div class="float-left col-6 p-6">
    </div>
</div>
