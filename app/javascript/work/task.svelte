<script>
    import { preventDefault } from 'svelte/legacy';

    import * as Tabs from "$lib/components/ui/tabs";
    import Members from './task_users.svelte';
    import Kits from './kits.svelte';
    import KitBatches from './kit_batches.svelte';
    import NewBatches from './new_batches.svelte';
    import Duals from './duals.svelte';
    import InputText from './input_text.svelte';
    import InputSelect from './input_select.svelte';
    import InputCheckbox from './input_checkbox.svelte';
    import Nodes from './xodes.svelte';
    export const lead_annotator = false;

    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [project_admin]
     * @property {any} project_id
     * @property {any} task_id
     * @property {any} project_users
     * @property {any} [info]
     * @property {any} id
     * @property {any} name
     * @property {any} status
     * @property {any} workflow_id
     * @property {any} workflows
     * @property {any} kit_type_id
     * @property {any} kit_types
     * @property {any} data_set_id
     * @property {any} data_sets
     * @property {any} task_admin_bool
     * @property {any} task_users
     * @property {any} class_def
     * @property {any} tables
     * @property {any} ann
     * @property {any} ann2
     * @property {any} diff
     * @property {any} source_uid
     * @property {any} meta
     * @property {any} features
     * @property {any} tasks
     * @property {any} bucket
     * @property {any} bucket_size
     * @property {any} reload
     */

    /** @type {Props} */
    let {
        help,
        project_admin = false,
        project_id,
        task_id,
        project_users,
        info = null,
        id,
        name = $bindable(),
        status,
        workflow_id,
        workflows,
        kit_type_id,
        kit_types,
        data_set_id,
        data_sets = $bindable(),
        task_admin_bool,
        task_users,
        class_def,
        tables,
        ann,
        ann2,
        diff,
        source_uid,
        meta,
        features,
        tasks,
        bucket,
        bucket_size,
        reload
    } = $props();
    let unused = source_uid && class_def && tables && ann && ann2 && diff;

    let page = 2;
    if(info){
        page = 1;
    }
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Task Info', 'all', 'task attributes' ],
        [ 'Kits', 'all', 'kits in this task' ],
        [ 'Duals', 'all', 'duals in this task' ],
        [ 'Task Members', 'admin', 'members of this task' ],
        [ 'Batches', 'admin', 'kit batches' ],
        [ 'Nodes', 'admin', 'nodes' ]
        [ 'New Batches', 'admin', 'nb' ]
    ];
    let url = `/projects/${project_id}/tasks/${task_id}`;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'User', 'user_id', 'col-1' ],
        [ 'Admin', 'admin', 'col-1' ]
    ]
    let statuses = [ 'active', 'inactive' ];
    let workflow = $state();
    let workflows_menu = [];
    for(let x of workflows){
        if(
            (
                x.name != 'Bucket' &&
                x.name != 'BucketUser' &&
                x.name != 'SecondPass'
            )
            ||
            x.id == workflow_id
        ){
            workflows_menu.push(x);
        }
        if(x.id == workflow_id){
            workflow = x;
            // break;
        }
    }
    let kit_type = $state();
    for(let x of kit_types){
        if(x.id == kit_type_id){
            kit_type = x;
            break;
        }
    }
    let data_set = $state();
    data_sets = [ { id: null, name: 'none'} ].concat(data_sets);
    for(let x of data_sets){
        if(x.id == data_set_id){
            data_set = x;
            break;
        }
    }
    let menu_task = $state();
    let menu_tasks = [ { id: 0, name: 'none'} ].concat(tasks);
    if(meta['1p_task_id']){
        for(let x of tasks){
            if(x.id == Number(meta['1p_task_id'])){
                menu_task = x;
                break;
            }
        }
    }
    else{
        menu_task = menu_tasks[0];
    }
    let constraintb = $state({});
    for(let x of features){
        if(x.name == x.value){
            constraintb[x.name] = meta[x.name] == x.name;
        }
        else{
            constraintb[x.name] = meta[x.name];
        }
    }
    let tab = $state('info');
    function tabs(x){
        tab = x;
    }
</script>

<style>
</style>


<!-- <PageTabs {help} {pages} {page} on:page={pagef} admin={task_admin_bool} /> -->

<Tabs.Root value="info" class="w-full justify-center" onValueChange={tabs}>
    <Tabs.List>
        <Tabs.Trigger value="info">Task Info</Tabs.Trigger>
        <Tabs.Trigger value="kits">Kits</Tabs.Trigger>
        <Tabs.Trigger value="duals">Duals</Tabs.Trigger>
        <Tabs.Trigger value="members">Task Members</Tabs.Trigger>
        <Tabs.Trigger value="batches">Batches</Tabs.Trigger>
        <Tabs.Trigger value="nodes">Nodes</Tabs.Trigger>
        <Tabs.Trigger value="nb">New Batches</Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value="info">
        {#if tab == 'info'}
    {#if project_admin}
        <div class="w-96 mx-auto">
            <div>ID: {id}</div>
            <form onsubmit={preventDefault(()=>null)}>
                <InputText   {url} label=Name key=name bind:value={name} />
                <InputSelect {url} label=Status key=status value={status} values={statuses} />
                <InputSelect {url} label=Workflow key="workflow_id" value={workflow} values={workflows_menu} att=name />
                <InputSelect {url} label=KitType key="kit_type_id" value={kit_type} values={kit_types} att=name />
                <InputSelect {url} label=DataSet key="data_set_id" value={data_set} values={data_sets} att=name />
                {#each features as x}
                    {#if x.name == x.value}
                        <InputCheckbox {url} label={x.label} key={x.name} value={constraintb[x.name]} meta={'meta'} />
                    {:else if x.name == '1p_task_id'}
                        <InputSelect {url} label={x.label} key={x.name} value={menu_task} values={menu_tasks} att=name meta={'meta'} />
                    {:else if x.name == 'docid' || x.name == 'notes' || x.name == 'dual_percentage' || x.name == 'dual_minimum_duration'}
                        <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta={'meta'} />
                    {:else}
                        <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} />
                    {/if}
                {/each}
            </form>
            <div>
                {#if bucket}
                    Bucket {bucket} has {bucket_size} files
                {:else}
                    no bucket for this task
                {/if}
            </div>
        </div>
    {:else}
        <div class="col-3 mx-auto">
            <div>ID: {id}</div>
            <div>Name: {name}</div>
        </div>
    {/if}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="kits">
        {#if tab == 'kits'}
    <Kits
        {help}
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
    />
        {/if}
    </Tabs.Content>
    <Tabs.Content value="duals">
        {#if tab == 'duals'}
    <Duals
        {help}
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
        {meta}
    />
        {/if}
    </Tabs.Content>
    <Tabs.Content value="members">
        {#if tab == 'members'}
    <Members
        {project_id}
        {task_id}
        task_admin={task_admin_bool}
        {task_users}
        {project_users}
        {reload}
    />
        {/if}
    </Tabs.Content>
    <Tabs.Content value="batches">
        {#if tab == 'batches'}
    {#if project_admin || lead_annotator || task_admin_bool}
        <KitBatches
            {help}
            {project_id}
            {task_id}
            task_admin={task_admin_bool}
            {task_users}
        />
    {:else}
        Permission Denied
    {/if}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="nodes">
        {#if tab == 'nodes'}
    {#if project_admin || lead_annotator || task_admin_bool}
        <Nodes
            {project_id}
            {task_id}
        />
    {:else}
        Permission Denied
    {/if}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="nb">
        {#if tab == 'nb'}
    {#if project_admin || lead_annotator || task_admin_bool}
        <NewBatches
            {help}
            {task_id}
            task_admin={task_admin_bool}
            {task_users}
        />
    {:else}
        Permission Denied
    {/if}
        {/if}
    </Tabs.Content>
</Tabs.Root>
