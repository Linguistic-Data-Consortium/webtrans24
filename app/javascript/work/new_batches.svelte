<script>
    import { getp, postp, deletep, patchp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Kit from './kit.svelte'
    import { btn1, cbtn } from './buttons';
    const btn = btn1;
    import { fi_select } from './form_inputs'
    import { toast } from "svelte-sonner";
    export let help;
    export let project_id;
    export let task_id;
    export let task_admin = false;
    // export let kits;
    export let task_users;
    let name;
    let p;
    // function get(){ p = getp(`/kit_batches?task_id=${task_id}`).then( (x) => console.log(x) ) } ///`) }
    function get(){ p = getp(`/control_docs?task_id=${task_id}`) }
    get();
    p.then( (x) => console.log(x));
    let columns = [
        [ 'Name', 'name', 'col-3' ],
        [ 'User', 'user_name', 'col-1' ],
        // [ 'Task', 'task_name', 'col-3' ],
        [ 'Kit Count', 'kit_creations_count', 'col-1' ],
        [ 'State', 'state', 'col-1' ],
        [ 'Creation Type', 'creation_type', 'col-1' ],
        [ 'Kit Creator', 'kit_creator', 'col-1' ],
        [ 'Created by', 'created', 'col-1' ],
        [ 'Block', 'block', 'col-1' ]
    ];
    const createm = {
        name: 'create_task_modal',
        title: 'Create Task',
        h: '',
        btnc: btn
    };
    const deletem = {
        name: 'delete_task_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete Task',
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
            else if(data.uids){
                flash_value = `${data.uids.success.length} modified, ${data.uids.error.length} failed`;
                get();
            }
            else{
                flash_value = "created " + data.task.name;
            }
            toast.success(flash_value);
            // setTimeout( () => reload() , 1000 );
        }
    }
    function create(){
        window.location = '/kit_batches/new';
        return
        postp(
            `/projects/${project_id}/tasks`,
            { name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/projects/${project_id}/tasks/${task_id}`
        ).then(response);
    }
    let kit_id;
    let kit_index;
    let pp;
    function open(){
        // pp = getp(`/kit_batches/${kit_id}`)
        window.open(`/kit_batches/${kit_id}`, '_blank');
    }
    function back(){
        pp = null;
    }
    function reload(e){
        pp = null;
        get();
    }
    let table;
    function reassign(){
        let uids = [];
        for(let x of table.get_matched()){
            uids.push(x.uid);
        }
        let o = { uids: uids.join(',') };
        if(!table.match_attempted()){
            toast.error("you haven't matched any kits");
        }
        else if(new_user || new_state){
            if(new_user){
                o.new_user = new_user.name;
            }
            if(new_state){
                o.new_state = new_state;
            }
            patchp(
                `/projects/${project_id}/tasks/${task_id}/reassign_many_kits`,
                o
            ).then(response);
        }
        else{
            toast.error('neither user nor state specified');
        }
    }
    function reassign2(a){
        let uids = [];
        for(let x of a){
            if(x.length > 0){
                uids.push(x);
            }
        }
        let o = { uids: uids.join(',') };
        if(uids.length == 0){
            toast.error("you haven't provided any kits");
        }
        else if(new_user || new_state){
            if(new_user){
                o.new_user = new_user.name;
            }
            if(new_state){
                o.new_state = new_state;
            }
            patchp(
                `/projects/${project_id}/tasks/${task_id}/reassign_many_kits`,
                o
            ).then(response);
        }
        else{
            toast.error('neither user nor state specified');
        }
    }
    let new_user;
    let new_state;
    let states = [ 'unassigned', 'assigned', 'done', 'broken', 'excluded', 'priority' ];
    let files;
    function upload(){
        const r = new FileReader();
        let o = null;
        r.onload = function(e){
            let a = e.target.result.split(/\r?\n/);
            reassign2(a);
        }
        r.readAsText(files[0]);
    }
 </script>

<style>
</style>

{#await p}
    loading...
{:then rows}
    {#if pp}
        <div class="float-right">
            <button class={btn} on:click={back}>Return to kit list</button>
        </div>
        {#await pp}
            <div><span>Loading</span><span class="AnimatedEllipsis"></span></div>
        {:then attributes}
            <Kit {task_admin} {attributes}
              {task_users}
              on:reload={reload}
            />
                <!-- {project_id} -->
                 <!-- {task_id} -->
            <!-- {task_id} {kit_index[task_id].name} -->
        {/await}
    {:else}
        <div class="flex justify-around items-center my-3">
            <!-- {#if task_admin} -->
            {#if false}
                <div class="font-semibold self-start">All Kits</div>
                <details>
                    <summary class={btn}>
                        Bulk Reassign
                    </summary>
                    <div>
                        <div class="italic my-2">Reassign all matched kits in table below</div>
                        <form>
                          <div class="form-input-box mb-2">
                              <label>
                                  User
                                  <select bind:value={new_user} class={fi_select}>
                                      <option value={null}>don't change</option>
                                      <option value={{name: ''}}>empty</option>
                                      {#each task_users as x}
                                          <option value={x}>{x.name}</option>
                                      {/each}
                                  </select>
                              </label>
                          </div>
                            <div class="form-input-box mb-2">
                              <label>
                                  State
                                  <select bind:value={new_state} class={fi_select}>
                                      <option value={null}>don't change</option>
                                      {#each states as x}
                                          <option value={x}>{x}</option>
                                      {/each}
                                  </select>
                              </label>
                            </div>
                        </form>
                    </div>
                    <div class="flex justify-around my-2">
                        <div><button class={btn} on:click={reassign}>Reassign</button></div>
                        <details class="ml-2">
                            <summary class={`${btn}`}>
                                Or Upload UID List
                            </summary>
                            <div>
                                <div class="italic my-2">Reassign listed kits (list uids)</div>
                                <div class="form-input-box">
                                    <input type="file" bind:files>
                                    {#if files && files[0]}
                                        <div>{files[0].name}</div>
                                        <div><button class={btn} on:click={upload}>upload</button></div>
                                    {/if}
                                </div>
                            </div>
                        </details>
                    </div>
                </details>
            {:else}
                <div>Kit Batches</div>
            {/if}
            {#if kit_id}
                <div>
                    <button class={cbtn} on:click={open}>Open</button>
                </div>
<!--                {#if task_admin}
                    <Modal {...deletem}>
                        <div slot=summary>
                            Delete
                        </div>
                        <div slot=body>
                            This will delete the task {kit_index[task_id].name}, are you sure you want to do this?
                        </div>
                    </Modal>
                {/if}
 -->            {/if}
            {#if task_admin}
                <button class="{cbtn}" on:click={create}>Create Kit Batch</button>
<!--                 <Modal {...createm}>
                    <div slot=summary>
                        Create Task
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
                        <button type="button" class={cbtn}   data-close-dialog on:click={create}>Create</button>
                    </div>
                </Modal>
 -->            {/if}
        </div>
        <hr>
        <Help {help}>
            <div slot=content>
                <p>The table can be filtered by user, state, and text (which matches any column)</p>
                <p>The filters are conjoined (all must be true)</p>
                <p>The Bulk Reassign feature depends on these filters; the filters select the kits to be reassigned</p>
            </div>
        </Help>
        <Table
            bind:this={table}
            bind:selected={kit_id}
            indexf={x => kit_index = x}
            {columns}
            {rows}
            use_filter={true}
            key_column=id
            download={true}
        />
    {/if}
 {/await}
