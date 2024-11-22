<script>
    import Help from './help.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} p
     * @property {any} project
     * @property {any} task
     */

    /** @type {Props} */
    let {
        help,
        admin = false,
        lead_annotator = false,
        p,
        project,
        task
    } = $props();
    let columns = [
        [ 'Project',   'project', 'col-1', 'f', (x, y) => goto(x, y) ],
        [ 'Task',      'task',    'col-2', 'f', (x, y) => goto(x, y) ],
        [ 'Action',    'action',  'col-1', 'html' ],
        [ 'Status',    'state',   'col-1' ],
        [ 'Done Kits', 'done',    'col-1' ]
    ]
    function goto(x, y){
        if(x.task_id){
            if(y == 'project') project(x);
            if(y == 'task') task(x);
        }
    }
</script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>These are your tasks</p>
        <p>The Action column contains links to annotation tools, if work is available</p>
        <p>Clicking on a Project or Task name will jump to the appropriate tab</p>
    </div>
    {/snippet}
</Help>


{#await p}
    loading...
{:then v}
    <Table {columns} rows={v[0]} use_filter={true} key_column=task height=400 selectedf={() => null}/>
{/await}
