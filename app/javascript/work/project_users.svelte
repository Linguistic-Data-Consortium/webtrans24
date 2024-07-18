<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import ProjectUser from './project_user.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    export let project_id;
    export let project_owner = false;
    export let project_admin = false;
    export let project_users;
    let project_users_refresh = 0;
    let project_user_table;
    let columns = [
        [ 'User ID', 'user_id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ],
        [ 'Owner', 'owner', 'col-1' ],
        [ 'Admin', 'admin', 'col-1' ],
    ];
    const deletem = {
        name: 'delete_project_user_modal',
        title: 'Remove Member',
        h: '',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ]
    };
    function refresh(e){
        if(e && e.detail){
            let h = e.detail;
            let project_user = project_users.find( pu => pu.id == h.id );
            if(h.hasOwnProperty('owner')) project_user.owner = h.owner;
            else if(h.hasOwnProperty('admin')) project_user.admin = h.admin;
        }
        project_user_table.reset_rows(project_users);
        project_users_refresh += 1;
    }
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
                if(data.project_user){
                    project_users.push(data.project_user);
                    refresh();
                }
            }
            // setTimeout( () => dispatch('reload', '') , 1000 );
        }
    }
    function create(){
        postp(
            `/project_users`,
            { project_id: project_id, user_id: user_id }
        ).then(response);
    }
    function destroy(){
        project_users = project_users.filter( pu => pu.id !== parseInt(project_user_id) );
        deletep(
            `/project_users/${project_user_id}`
        ).then(response);
    }
    let project_user_id;
    let project_user_index;
    let name;
    let user_id;
    let pp;
    // $: pp = getp(`/projects/${project_id}/users_not_in_project?term=${name}`)
    function back(){
        pp = null;
    }
    const urlf = (name) => `/projects/${project_id}/users_not_in_project?term=${name}`;
    // $: auto(name);
    function auto2(x){
        user_id = x.id;
        create();
    }
    let is_owner;
    let is_admin;
    $: {
        if(project_user_id){
            is_owner = project_user_index[project_user_id].owner;
            is_admin = project_user_index[project_user_id].admin;
        }
    }
</script>

<style>
</style>


{#if flash_type}
    <div class="text-center flash flash-{flash_type} mb-3">
        {flash_value}
        <button type=button class="close flash-close js-flash-close">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
        </button>
    </div>
{/if}
<div class="flex justify-around items-center my-3">
    <div class="font-semibold">Members</div>
    {#if project_user_id}
        {#if project_admin}
            <Modal {...deletem}>
                <div slot=summary>
                    Remove User
                </div>
                <div slot=body>
                    This will remove {project_user_index[project_user_id].name}, are you sure you want to do this?
                </div>
            </Modal>
        {/if}
    {/if}
    {#if project_admin}
        <SelectUsers {urlf} {create} {auto2} />
    {/if}
</div>
<div class="flex justify-aroundx p-6">
    <div class="w-1/2 col-{project_user_id ? '6' : '12'}">
        {#key project_users_refresh}
            <Table
                bind:this={project_user_table}
                bind:selected={project_user_id}
                bind:index={project_user_index}
                {columns}
                rows={project_users}
                use_filter={true}
                key_column=id
                height=400
            />
        {/key}
    </div>
    <div class="float-left col-6 p-6">
        {#if project_user_id && project_owner}
            {#each project_users as x}
                {#if x.id == project_user_id}
                    <ProjectUser id={x.id} is_owner={x.owner} is_admin={x.admin} on:refresh={refresh} />
                {/if}
            {/each}
        {/if}
    </div>
</div>
