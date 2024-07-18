<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    export let help;
    export let admin = false;
    export let lead_annotator = false;
    let unused = admin && lead_annotator;
    export let p;
    let columns = [
        [ 'Project',   'project', 'col-1', 'f', (x, y) => goto(x, y) ],
        [ 'Task',      'task',    'col-2', 'f', (x, y) => goto(x, y) ],
        [ 'Action',    'action',  'col-1', 'html' ],
        [ 'Status',    'state',   'col-1' ],
        [ 'Done Kits', 'done',    'col-1' ]
    ]
    function goto(x, y){
        if(x.task_id) dispatch(y, x);
    }
</script>

<style>
</style>

<Help {help}>
    <div slot=content>
        <p>These are your tasks</p>
        <p>The Action column contains links to annotation tools, if work is available</p>
        <p>Clicking on a Project or Task name will jump to the appropriate tab</p>
    </div>
</Help>


{#await p}
    loading...
{:then v}
    <Table {columns} rows={v[0]} use_filter={true} key_column=task height=400 />
{/await}
