<script>
    import { cbtn } from "./buttons"
    import { getp, postp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte';
    import Spinner from './spinner.svelte'
    export let admin = false;
    export let portal_manager = false;
    export let project_manager = false;
    let p;
    function get(){
        p = getp('/invites')
    }
    get();
    let columns = [
        [ 'Email', 'email', 'col-1' ],
        [ 'Sent', 'sent', 'col-1' ],
        [ 'Activated', 'activated', 'col-1' ]
    ]
    const h = {
        name: 'create_invitation_modal',
        // delegate: ns,
        // b: 'DELETE',
        // f: "delete_section_from_modal",
        // ff: delete_selected,
        title: 'Send Invitation',
        h: '',
        buttons: [
            [ 'Send', cbtn, create_invite ]
        ]
    };
    let email;
    let flash_type = null;
    let flash_value;
    let role;
    let project_id;
    let task_id;
    function create_invite(){
        postp(
            "/invites",
            {
                email: email,
                role: role,
                task_id: task_id,
                project_id: project_id
            }
          ).then( (data) => {
                if(data.errors){
                    flash_type = 'error';
                    flash_value = data.errors.join(' ');
                }
                else{
                    flash_type = 'success';
                    flash_value = "sent to " + data.invite.email;
                    get();
                }
            }
          );
    }
</script>

<style>
</style>

{#if project_manager}
    {#if flash_type}
        <div class="text-center flash flash-{flash_type}">
            {flash_value}
            <button type=button class="close flash-close js-flash-close">
                <i class="fa fa-times"></i>
            </button>
        </div>
    {/if}
    <div class="flex justify-around">
        <div>
            Invitations you made
        </div>
        <Modal {...h}>
            <div slot=summary>
                Send Invitation
            </div>
            <div slot=body>
                <form on:submit|preventDefault={()=>null}>
                    <div>
                        <label>Email
                            <input type=text bind:value={email}/>
                        </label>
                    </div>
                    {#if admin || portal_manager}
                        <div class="pt-2">
                            Optionally, give the person a special role.
                        </div>
                    {/if}
                    {#if admin}
                        <div>
                            <label>
                            	<input type=radio bind:group={role} value={"Project Manager"}>
                            	Project Manager
                            </label> 
                        </div>
                    {/if}
                    {#if portal_manager}
                        <div>
                            <label>
                            	<input type=radio bind:group={role} value={"Portal Manager"}>
                            	Portal Manager
                            </label> 
                        </div>
                    {/if}
                    {#if project_manager}
                        <div class="pt-2">
                            <div>If you want to automatically add the invitee to</div>
                            <div>a project and/or task, select those here.</div>
                        </div>
                        {#await p}
                          <div class="mx-auto w-8 h-8"><Spinner /></div>
                        {:then v}
                            <div>
                                <label for=x>Project</label>
                                <select id=x class="form-select" bind:value={project_id}>
                                    <option value={null}></option>
                                    {#each v.projects as project}
                                        <option value={project.id}>
                                            {project.name}
                                        </option>
                                    {/each}
                                </select>
                            </div>
                            <div>
                                {#if project_id && project_id != v.personal}
                                    <label for=y>Task</label>
                                    <select id=y class="form-select" bind:value={task_id}>
                                        <option value={null}></option>
                                        {#each v.tasks_index[project_id] as task}
                                            <option value={task.id}>
                                                {task.name}
                                            </option>
                                        {/each}
                                    </select>
                                {/if}
                            </div>
                        {/await}
                    {/if}
                    <!-- <select class="form-select" aria-label="Important decision">
                        <option>Select</option>
                        <option value="option 2">Option 2</option>
                      </select> -->
                </form>
            </div>
            <!-- <div slot=footer>
                <button type="button" class="{btn}"   data-close-dialog on:click={create_invite}>Send</button>
            </div> -->
        </Modal>
    </div>
    {#await p}
      <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        <Table {columns} rows={v.users} use_filter={true} key_column=email height=500 />
    {/await}
{:else}
    Not allowed
{/if}
