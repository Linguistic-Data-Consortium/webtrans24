<script>
    import { run } from 'svelte/legacy';

    import { postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import ProjectUser from './project_user.svelte'
    import SelectUsers from './select_users.svelte'
    import { btn, dbtn } from './buttons'
    import { toast } from "svelte-sonner";
    /**
     * @typedef {Object} Props
     * @property {any} project_id
     * @property {boolean} [project_owner]
     * @property {boolean} [project_admin]
     * @property {any} project_users
     */

    /** @type {Props} */
    let {
        project_id,
        project_owner = false,
        project_admin = false,
        project_users = $bindable()
    } = $props();
    let project_users_refresh = $state(0);
    let project_user_table = $state();
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
                flash_value = data.ok;
                if(data.project_user){
                    project_users.push(data.project_user);
                    refresh();
                }
            }
            toast.success(flash_value);
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
    let project_user_id = $state();
    let project_user_index = $state();
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
    let is_owner = $state();
    let is_admin = $state();
    run(() => {
        if(project_user_id){
            is_owner = project_user_index[project_user_id].owner;
            is_admin = project_user_index[project_user_id].admin;
        }
    });
</script>

<style>
</style>


<div class="flex justify-around items-center my-3">
    <div class="font-semibold">Members</div>
    {#if project_user_id}
        {#if project_admin}
            <Modal {...deletem}>
                {#snippet summary()}
                <div >
                    Remove User
                </div>
                {/snippet}
                {#snippet body()}
                <div >
                    This will remove {project_user_index[project_user_id].name}, are you sure you want to do this?
                </div>
                {/snippet}
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
                indexf={x => project_user_index = x}
                {columns}
                rows={project_users}
                use_filter={true}
                key_column=id
                height=400
                selectedf={() => null}
            />
        {/key}
    </div>
    <div class="float-left col-6 p-6">
        {#if project_user_id && project_owner}
            {#each project_users as x}
                {#if x.id == project_user_id}
                    <ProjectUser id={x.id} is_owner={x.owner} is_admin={x.admin} {refresh} />
                {/if}
            {/each}
        {/if}
    </div>
</div>
