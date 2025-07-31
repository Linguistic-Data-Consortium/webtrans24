<script>
    import { getp, patchp } from '../lib/ldcjs/getp';
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Kit from './kit.svelte'
    import Spinner from '../lib/ldcjs/work/spinner.svelte';
    import { btn, dbtn } from '../lib/ldcjs/work/buttons';
    import { toast } from "svelte-sonner";
    export let project_id;
    export let task_id;
    export let task_admin = false;
    let p;
    function get(){ p = getp(`/kits/task/${task_id}`).then( x => x.filter(x => x.state == 'done' )) }
    get();
    p.then( (x) => console.log(x) )
    export let task_users;
    export let reload;
    let name;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'UID', 'uid', 'col-1', 'f', (x, y) => window.open(x.link) ],
        [ 'Source', 'source_uid', 'col-1' ],
        [ 'User', 'user', 'col-1', 'filter' ],
        [ 'Done Comment', 'done_comment', 'col-1' ],
    ];
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
            setTimeout( () => reload() , 1000 );
        }
    }
    let kit_id;
    let kit_index;
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
    let new_user;
    let new_state;
    let states = [ 'unassigned', 'assigned', 'done', 'broken', 'excluded', 'priority' ];
    const reassignm = {
        title: 'Create Kits',
        buttons: [
            [ 'Reassign', btn, reassign ]
        ]
    };
    let emptyv = { name: '' };
 </script>

<style>
</style>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then rows}
        <div class="flex justify-around mb-4">
            {#if task_admin}
                <div>All Done Kits</div>
                <Modal {...reassignm}>
                    <div slot=summary>
                        Bulk Reassign
                    </div>
                    <div slot=body>
                        <div>Reassign all matched kits in table below</div>
                        <div>
                            <label>
                                User
                                <select bind:value={new_user}>
                                    <option value={null}>don't change</option>
                                    <option value={emptyv}>none</option>
                                    {#each task_users as x}
                                        <option value={x}>{x.name}</option>
                                    {/each}
                                </select>
                            </label>
                            <label>
                                State
                                <select bind:value={new_state}>
                                    <option value={null}>don't change</option>
                                    {#each states as x}
                                        <option value={x}>{x}</option>
                                    {/each}
                                </select>
                            </label>
                        </div>
                    </div>
                </Modal>
            {:else}
                <div>My Done Kits</div>
            {/if}
        </div>
        <hr>
        <Table
            bind:this={table}
            bind:selected={kit_id}
            indexf={x => kit_index = x}
            {columns}
            {rows}
            use_filter={true}
            key_column=id
            height=400
            download={true}
        />
 {/await}
