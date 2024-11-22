<script>
    import { Toaster } from "$lib/components/ui/sonner";
    import * as Tabs from "$lib/components/ui/tabs";
    import * as Tooltip from "$lib/components/ui/tooltip";
    import * as Dialog from "$lib/components/ui/dialog";
    import { Label } from "$lib/components/ui/label";
    import { Input } from "$lib/components/ui/input";
    import { Button, buttonVariants } from "$lib/components/ui/button";
    import { btn, cbtn, dbtn } from "./buttons"
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Help from './help.svelte';
    import UsersTasks from './users_tasks.svelte';
    import Projects from './projects.svelte';
    import KitTypes from './kit_types.svelte';
    import ClassDefs from './class_defs.svelte';
    import XlassDefs from './xlass_defs.svelte';
    import DataSets from './data_sets.svelte';
    import Invites from './invites.svelte';
    import Browse from './browse_f.svelte';
    import Spinner from './spinner.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Patch from './patch.svelte';
    import InputText from './input_text.svelte';
    import InputSelect from './input_select.svelte';
    import InputCheckbox from './input_checkbox.svelte';
    import ProjectUser from './project_user.svelte';
    import TaskUser from './task_user.svelte';
    import Kits from './kits.svelte';
    import { controller_actions } from './controllers';
    import { toast } from "svelte-sonner";
    import { response, ok_reload } from './helpers';
    let { admin = false, portal_manager = false, project_manager = false } = $props();
    let lead_annotator = $state(project_manager);
    let help = $state(false);
    // let page = 1;
    // function pagef(e){ page = e.detail }
    // let pages = [
    //     [ 'Work',        'all',            "your tasks with links to start" ],
    //     [ 'Projects',    'all',            'projects, tasks, kits' ],
    //     [ 'Browse',      'all',            'browse uploaded files' ],
    //     [ 'Kit Types',   'lead_annotator', 'tasks require a kit type' ],
    //     [ 'Namespaces',  'lead_annotator', 'kit types require a namespace' ],
    //     [ 'Tools',       'lead_annotator', 'kit types require a namespace' ],
    //     [ 'Data Sets',   'lead_annotator', 'tasks can have a data set' ],
    //     [ 'Invites',     'lead_annotator', 'invite people to the site' ],
    //     [ 'Scripts',     'lead_annotator', 'write scripts' ],
    //     [ 'Features',    'admin',          'features for different objects' ],
    //     [ 'Services',    'admin',          'services' ],
    //     [ 'Workflows',   'admin',          'workflows' ],
    //     [ 'Groups',      'admin',          'groups' ],
    //     [ 'Permissions', 'all',            'explore roles and permissions' ]
    // ];
    // let goto_project = $state();
    function goto(x, y){
        if(x.task_id){
            tab = 'projects';
            if(y == 'project') project(x);
            if(y == 'task') task(x);
        }
    }
    function project(e){
        actions.project.get_all();
        all_label = (lead_annotator ? "All" : "My") + " Projects";
        if(e){
            models.project.id = e.project_id;
            models.task.id = null;
            actions.project.get_one('tasks');
        }
    }
    // let goto_task = $state();
    function task(e){
        project(e);
        models.task.id = e.task_id;
        actions.task.get_one('kits');
    }
    // document.getElementById('work1').hidden = true;
    function helpf(e){
        alert(e.detail);
    }
    
    export function browse(x){
        tab = 'browse';
        // browse_a.step1(x);
    }
    let browsex = $state();
    export function uploads(e){
        // page5();
        // browsex.get(e);
    }
    let p = getp(window.location);
    console.log('USERS');
    p.then( (x) => console.log(x) )
    let goto_data_set = $state();
    function reload2(e){
        // page = 6;
        // goto_data_set = e.detail.id;
    }
    let tab = $state('tasks');
    let tabp = $state(Promise.resolve([]));
    let pp = $state();
    let taskpp = $state();
    let taskuserpp = $state();
    let style = $state();
    let style_timeout;
    function set_style(e){
        style = `position: absolute; left: ${e.pageX-20}px; top: ${e.pageY+20}px; z-index: 10`;
        if(style_timeout) clearTimeout(style_timeout);
        style_timeout = setTimeout( () => style = null, 2000);
    };
    let member_timeout;
    let memberp = $state(Promise.resolve([]));
    let member_name = $state();
    function memberf(name){
        if(models.task.tab == 'members'){
            return pp.then(x => x.members);
        }
        else if(models.project.tab == 'members'){
            return controller_actions.project_user.not_in(models.project.id, name);
        }
        else if(models.group.tab == 'members'){
            return controller_actions.group_user.not_in(models.group.id, name);
        }
    }
    // use a named function so effect only binds to member_name
    $effect(() => check_member_name(member_name));
    function check_member_name(name){
        if(!name || name.length < 3){
            memberp = Promise.resolve([]);
            return;
        }
        if(typeof(memberf) == 'object'){
            memberp = Promise.resolve(memberf);
            return;
        }
        if(member_timeout) clearTimeout(member_timeout);
        member_timeout = setTimeout(() => memberp = memberf(name), 500);
    }
    function create_name(){
        return { name: document.getElementById('dialog_create_name').value };
    }
    function create_category(){
        return { category: document.getElementById('dialog_create_category').value };
    }
    function member_create(model, x){
        let o = { user_id: x.id };
        if(model == 'task') o.user_id = x.user_id;
        o[model + '_id'] = models[model].id;
        controller_actions[model + '_user'].create(o)
        .then(x => ok_reload(x, () => actions[model].get_one('members')))
        .then(member_name = null);
    }
    function member_delete(model){
        controller_actions[model + '_user'].delete(models[model].user_id)
        .then(x => ok_reload(x, () => actions[model].get_one('members')))
        .then(models[model].user_id = null);
    }
    function selectedfmember(model, x){
        models[model].user_id = x;
        if(model == 'task') taskuserpp = x && controller_actions.task_user.get_one(x);
    }
    let all_label = $state();
    function tabs(tab){
        pp = null;
        taskpp = null;
        switch(tab){
            case 'projects':
                project();
                break;
            case 'kit_types':
                actions.kit_type.get_all();
                all_label = "All Kit Types";
                break;
            case 'features':
                actions.feature.get_all();
                all_label = "All Features";
                break;
            case 'workflows':
                actions.workflow.get_all();
                all_label = "All Workflows";
                break;
            case 'groups':
                actions.group.get_all();
                all_label = "All Groups";
                break;
        }
    }


    const models = $state({
        kit_type: {
            label: 'Kit Type',
            desc: 'A Kit Type holds parameters for kit behavior.',
            id: null,
            index: null
        },
        project: {
            label: 'Project',
            desc: 'A Project is a set of Tasks and a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        },
        task: {
            label: 'Task',
            desc: 'A Task is a set of Kits and a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        },
        feature: {
            label: 'Feature',
            desc: 'A Feature is an attribute of an object.',
            id: null,
            index: null
        },
        workflow: {
            label: 'Workflow',
            desc: 'A Workflow controls kit assignment.',
            id: null,
            index: null
        },
        group: {
            label: 'Group',
            desc: 'A Group is a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        }
    });
    const actions = $derived.by(() => {
        const model_actions = {};
        for(let x in controller_actions){
            model_actions[x] = {};
            model_actions[x].get_all = () => {
                tabp = controller_actions[x].get_all();
                models[x].id = null;
            };
            model_actions[x].get_one = () => pp = controller_actions[x].get_one(models[x].id);
            model_actions[x].create = () => controller_actions[x].create(create_name()).then(y => response(y, model_actions[x].get_all));
            model_actions[x].delete = () => controller_actions[x].delete(models[x].id).then(y => response(y, model_actions[x].get_all, () => models[x].id = null));
            model_actions[x].patch = (y) => controller_actions[x].patch(models[x].id, y);
        }
        // overrides
        model_actions.project.get_one = (x) => {
            pp = controller_actions.project.get_one(models.project.id);
            taskpp = null;
            models.project.user_id = null;
            models.project.tab = x || 'info';
            // memberf = (name) => controller_actions.project_user.not_in(models.project.id, name);
        };
        model_actions.project_user.patch = (x) => controller_actions.project_user.patch(models.project.user_id, x);
        model_actions.task.get_one = (x) => {
            console.log(x)
            taskpp = controller_actions.task.get_one(models.project.id, models.task.id)
            .then(x => {
                x.statuses = [ 'active', 'inactive' ];
                x.workflow = null;
                x.workflows_menu = [];
                for(let y of x.workflows){
                    if(
                        (
                            y.name != 'Bucket' &&
                            y.name != 'BucketUser' &&
                            y.name != 'SecondPass'
                        )
                        ||
                        y.id == x.workflow_id
                    ){
                        x.workflows_menu.push(y);
                    }
                    if(y.id == x.workflow_id){
                        x.workflow = y;
                        // break;
                    }
                }
                for(let y of x.kit_types){
                    if(y.id == x.kit_type_id){
                        x.kit_type = y;
                        break;
                    }
                }
                x.data_sets = [ { id: null, name: 'none'} ].concat(x.data_sets);
                for(let y of x.data_sets){
                    if(y.id == x.data_set_id){
                        x.data_set = y;
                        break;
                    }
                }
                x.menu_tasks = [ { id: 0, name: 'none'} ].concat(x.tasks);
                if(x.meta['1p_task_id']){
                    for(let y of x.tasks){
                        if(y.id == Number(x.meta['1p_task_id'])){
                            x.menu_task = y;
                            break;
                        }
                    }
                }
                else{
                    x.menu_task = x.menu_tasks[0];
                }
                x.constraintb = {};
                for(let y of x.features){
                    if(y.name == y.value) x.constraintb[y.name] = x.meta[y.name] == y.name;
                    else                  x.constraintb[y.name] = x.meta[y.name];
                }
                console.log('taskusers', x)
                return x;
            });
            models.task.user_id = null;
            models.task.tab = x || 'info';
            taskuserpp = null;
            // memberf = (name) => controller_actions.task_user.not_in(models.task.id, name);
        };
        model_actions.task.create = () => {
            controller_actions.task.create(models.project.id, create_name())
            .then(y => response(y, () => model_actions.project.get_one('tasks')));
        };
        model_actions.task.delete = () => {
            controller_actions.task.delete(models.task.id)
            .then(y => response(y, () => model_actions.project.get_one('tasks'), () => models.task.id = null));
        };
        model_actions.task_user.patch = (x) => controller_actions.task_user.patch(models.task.user_id, x);
        model_actions.kit_type.get_one = () => {
            pp = controller_actions.kit_type.get_one(models.kit_type.id)
            .then(x => {
                for(let y of x.node_classes){
                    if(y.id == x.node_class_id){
                        x.node_class = y;
                        break;
                    }
                }
                x.constraintb = {};
                for(let y of x.features){
                    if(y.name == y.value) x.constraintb[y.name] = x.constraints[y.name] == y.name;
                    else                  x.constraintb[y.name] = x.constraints[y.name];
                }
                return x;
            });
        };
        model_actions.feature.create = () => {
            const { category } = create_category();
            const { name } = create_name();
            controller_actions.feature.create({ category, name })
            .then(x => response(x, model_actions.feature.get_all));
        };
        // model_actions.group.get_one = () => {
        //     pp = controller_actions.group.get_one(models.group.id);
        //     .then( x => {
        //         x.group_admin_bool
        //     });
        //     // memberf = (name) => controller_actions.group_user.not_in(models.group.id, name);
        // };
        return model_actions;
    });

    const task_user_states = [ null, 'needs_kit', 'has_kit', 'hold', 'paused' ];

</script>

<style>
</style>

<Toaster richColors expand={true} />

<Help {help}>
    {#snippet content()}
    <div>
        <p>Help Mode On</p>
        <p>more info can be found on each tab</p>
    </div>
    {/snippet}
</Help>

<div>
    {#if admin}
        <div>
          jump to readonly
          <input class="jtro">
        </div>
    {/if}
</div>

<button class="{btn} bg-blue-200 float-right" onclick={() => help = !help}>Help</button>

{#snippet dialog_create(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Create {models[model].label}</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Create {models[model].label}</Dialog.Title>
                <Dialog.Description>
                    {models[model].desc}
                </Dialog.Description>
            </Dialog.Header>
            {#if model == 'feature'}
                <Label for="dialog_create_category">Category</Label>
                <Input type="text" id="dialog_create_category" placeholder="Category" />
            {/if}
            <Label for="dialog_create_name">Name</Label>
            <Input type="text" id="dialog_create_name" placeholder="Name" />
            <Dialog.Footer>
                <Button variant="secondary" onclick={actions[model].create}>Create</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_delete(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Delete {models[model].label}</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Delete {models[model].label}</Dialog.Title>
                <Dialog.Description>
                    This will delete the {models[model].label} {models[model].index[models[model].id].name}, are you sure you want to do this?
                </Dialog.Description>
            </Dialog.Header>
            <Dialog.Footer>
                <Button variant="destructive" onclick={actions[model].delete}>Delete</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_create_member(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Add Member</Dialog.Trigger>
        <Dialog.Content style="width: 800px; max-width: 800px;">
            <Dialog.Header>
                <Dialog.Title>Add Member</Dialog.Title>
                <Dialog.Description>
                    Add User to {models[model].label}
                </Dialog.Description>
            </Dialog.Header>
            <div class="grid grid-cols-2">
                <div>
                    <Label for="dialog_create_member_name">Name</Label>
                    <Input type="text" id="dialog_create_member_name" placeholder="Name" bind:value={member_name} />
                </div>
                <div>
                    {#await memberp}
                        names
                    {:then v}
                        {#each v as x}
                            {#if x.name.includes(member_name)}
                                <button class="{buttonVariants({ variant: "secondary" })} m-2" onclick={() => member_create(model, x)}>{x.name}</button>
                            {/if}
                        {/each}
                    {/await}
                </div>
            </div>
            <!-- <Dialog.Footer>
                <Button variant="secondary" onclick={f}>Create</Button>
            </Dialog.Footer> -->
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_delete_member(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Remove Member</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Remove Member</Dialog.Title>
                <Dialog.Description>
                    This will remove {models[model].user_index[models[model].user_id].name}, are you sure you want to do this?
                </Dialog.Description>
            </Dialog.Header>
            <Dialog.Footer>
                <Button variant="destructive" onclick={() => member_delete(model)}>Delete</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet boiler1(model)}
    {@render boiler2(model)}
    {#await pp}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        {@render boiler4(v)}
        {@render boiler5(model, v)}
    {/await}
{/snippet}

{#snippet boiler2(model)}
    <div class="float-right">
        <button class="{btn}" onclick={() => (pp = null) || actions[model].get_all()}>Return to {models[model].label} list</button>
    </div>
{/snippet}

{#snippet boiler4(v)}
    <div class="float-right p-2">{v.name}</div>
{/snippet}

{#snippet boiler5(model, v)}
    <div class="w-96 mx-auto">
        <div>ID: {v.id}</div>
        {#if model == 'feature'}
            <Patch type="input" urlf={actions[model].patch} label="Category" key="category" value={v.category} />
        {/if}
        {#if model == 'project' && !v.project_owner_bool}
            <div>Name: {name}</div>
        {:else}
            <Patch type="input" urlf={actions[model].patch} label="Name" key="name" value={v.name} />
        {/if}
        {#if model == 'task'}
            {models.task.tab}
            <Patch type="select" urlf={actions[model].patch} label="Status" key="status" value={v.status} values={v.statuses} />
            <Patch type="select" urlf={actions[model].patch} label="Workflow" key="workflow_id" value={v.workflow} values={v.workflows_menu} att="name" />
            <Patch type="select" urlf={actions[model].patch} label="KitType" key="kit_type_id" value={v.kit_type} values={v.kit_types} att="name" />
            <Patch type="select" urlf={actions[model].patch} label="DataSet" key="data_set_id" value={v.data_set} values={v.data_sets} att="name" />
            {#each v.features as x}
                {#if x.name == x.value}
                    <Patch type="checkbox" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="meta" />
                {:else if x.name == '1p_task_id'}
                    <Patch type="select" urlf={actions[model].patch} label={x.label} key={x.name} value={v.menu_task} values={v.menu_tasks} att="name" meta="meta" />
                {:else if x.name == 'docid' || x.name == 'notes' || x.name == 'dual_percentage' || x.name == 'dual_minimum_duration'}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="meta" />
                {:else}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} />
                {/if}
            {/each}
            <div>
                {#if v.bucket}
                    Bucket {v.bucket} has {v.bucket_size} files
                {:else}
                    no bucket for this task
                {/if}
            </div>
        {/if}
        {#if model == 'kit_type'}
            <Patch type="select" urlf={actions[model].patch} label="Namespace" key="node_class_id" value={v.node_class} values={v.node_classes} att="name" />
            {#each v.features as x}
                {#if x.name == x.value}
                    <Patch type="checkbox" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" />
                {:else if x.value == 'comma'}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" split="," />
                {:else}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" />
                {/if}
            {/each}
        {:else if model == 'feature'}
            <Patch type="input" urlf={actions[model].patch} label="Value" key="value" value={v.value} />
            <Patch type="input" urlf={actions[model].patch} label="Label" key="label" value={v.label} />
            <Patch type="textarea" urlf={actions[model].patch} label="Description" key="description" value={v.description} textarea={true} />
        {:else if model == 'workflow'}
            <Patch type="textarea" urlf={actions[model].patch} label="Description" key="description" value={v.description} textarea={true} />
            <Patch type="select" urlf={actions[model].patch} label="Type" key="type" value={v.type} values={v.types} />
        {/if}
    </div>
{/snippet}

{#snippet boiler3(model, p1, p2)}
    <div class="flex justify-around">
        <div>{all_label}</div>
        {#if models[model].id && models[model].index}
            <div>
                <button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open</button>
            </div>
            {@render boiler7(model)}
            {#if p1}
                {@render dialog_delete(model)}
            {/if}
        {:else}
            Select a {models[model].label} in the table for more options.
        {/if}
        {#if p2}
            {@render dialog_create(model)}
        {/if}
    </div>
{/snippet}

{#snippet member_table(model, v, columns)}
    <Table
        indexf={x => models[model].user_index = x}
        {columns}
        rows={v.members}
        selectedf={(x) => selectedfmember(model, x)}
    />
{/snippet}


{#snippet member_tab(model, v)}
    {#if models[model].tab == "members"}
        <div class="flex justify-around">
            <div>Members</div>
            {#if v[model + '_admin_bool']}
                {#if models[model].user_id}
                    {@render dialog_delete_member(model)}
                {/if}
                {@render dialog_create_member(model)}
            {/if}
        </div>
        <div class="flex justify-aroundx p-6">
            <div class="float-leftx col-6 w-1/2">
                {#if model == 'project'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ],
                        [ 'Owner', 'owner', 'col-1' ],
                        [ 'Admin', 'admin', 'col-1' ]
                    ])}
                {:else if model == 'task'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ],
                        [ 'State', 'state', 'col-1' ],
                        [ 'Admin', 'admin', 'col-1' ]
                    ])}
                {:else if model == 'group'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ]
                    ])}
                {/if}
            </div>
            <div class="float-leftx col-6 p-6 w-1/2">
                {#if models[model].user_id && (v.project_owner_bool || v.task_admin_bool)}
                    {#each v.members as x}
                        {#if x.id == models[model].user_id}
                            {#if model == 'project'}
                                <div class="flex items-center space-x-4">
                                    <Patch type="checkbox" urlf={actions[model + '_user'].patch} label="Owner" key="owner" value={x.owner} reload={() => actions[model].get_one('members')} />
                                    <Patch type="checkbox" urlf={actions[model + '_user'].patch} label="Admin" key="admin" value={x.admin} reload={() => actions[model].get_one('members')} />
                                </div>
                            {:else if model == 'task'}
                                <div class="w-1/2">
                                    <Patch type="checkbox"   urlf={actions[model + '_user'].patch} label="Admin" key="admin" value={x.admin} reload={() => actions[model].get_one('members')} />
                                    {#if task_user_states.includes(x.state)}
                                        <Patch type="select" urlf={actions[model + '_user'].patch} label="State" key="state" value={x.state} reload={() => actions[model].get_one('members')} values={task_user_states} />
                                    {:else}
                                        Error
                                    {/if}
                                </div>
                                <div class="my-4">
                                    {#if taskuserpp}
                                        {#await taskuserpp}
                                            <div class="mx-auto w-8 h-8"><Spinner /></div>
                                        {:then v}
                                            <pre>
                                                {v.ok}
                                            </pre>
                                        {/await}
                                    {/if}
                                </div>
                            {/if}
                        {/if}
                    {/each}
                {/if}
            </div>
        </div>
    {/if}
{/snippet}

{#snippet boiler7(model)}
    {#if style}
        <div {style}>
            {#if model == 'project'}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open Project Info</button></div>
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one('tasks')}>Open Task List</button></div>
            {:else if model == 'task'}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open Task Info</button></div>
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one('kits')}>Open Kit List</button></div>
            {:else}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open</button></div>
            {/if}
        </div>
    {/if}
{/snippet}

<!-- <PageTabs {pages} {page} on:page={pagef} {admin} {lead_annotator} {help} on:help={helpf} /> -->

<Tabs.Root bind:value={tab} class="w-full justify-center" onValueChange={tabs}>
    <Tabs.List>
        <Tabs.Trigger value="tasks">
            <Tooltip.Root>
                <Tooltip.Trigger>Work</Tooltip.Trigger>
                <Tooltip.Content>your tasks with links to start</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="projects">
            <Tooltip.Root>
                <Tooltip.Trigger>Projects</Tooltip.Trigger>
                <Tooltip.Content>projects, tasks, kits</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="browse">
            <Tooltip.Root>
                <Tooltip.Trigger>Browse</Tooltip.Trigger>
                <Tooltip.Content>browse uploaded files</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="kit_types">
            <Tooltip.Root>
                <Tooltip.Trigger>Kit Types</Tooltip.Trigger>
                <Tooltip.Content>tasks require a kit type</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="features">
            <Tooltip.Root>
                <Tooltip.Trigger>Features</Tooltip.Trigger>
                <Tooltip.Content>features for different objects</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="workflows">
            <Tooltip.Root>
                <Tooltip.Trigger>Workflows</Tooltip.Trigger>
                <Tooltip.Content>workflows</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="groups">
            <Tooltip.Root>
                <Tooltip.Trigger>Groups</Tooltip.Trigger>
                <Tooltip.Content>users can be added to groups</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
        <Tabs.Trigger value="permissions">
            <Tooltip.Root>
                <Tooltip.Trigger>Permissions</Tooltip.Trigger>
                <Tooltip.Content>explore roles and permissions</Tooltip.Content>
            </Tooltip.Root>
        </Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value="tasks">
        <Help {help}>
            {#snippet content()}
            <div>
                <p>These are your tasks</p>
                <p>The Action column contains links to annotation tools, if work is available</p>
                <p>Clicking on a Project or Task name will jump to the appropriate tab</p>
            </div>
            {/snippet}
        </Help>
            <!-- <UsersTasks {help} {admin} {lead_annotator} {p} {project} {task} /> -->
        {#await p}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <Table
                indexf={x => null}
                columns={[
                    [ 'Project',   'project', 'col-1', 'f', (x, y) => goto(x, y) ],
                    [ 'Task',      'task',    'col-2', 'f', (x, y) => goto(x, y) ],
                    [ 'Action',    'action',  'col-1', 'html' ],
                    [ 'Status',    'state',   'col-1' ],
                    [ 'Done Kits', 'done',    'col-1' ]
                ]}
                rows={v[0]}
                key_column="task"
                selectedf={() => null}
            />
        {/await}
    </Tabs.Content>
    <Tabs.Content value="projects">
        {#if tab == 'projects'}
    <!-- <Projects   {help} {admin} {lead_annotator} {goto_project} {goto_task} {reload2} /> -->
            <Help {help}>
                {#snippet content()}
                    <div>
                        <p>Projects contain Tasks, which in turn contain Kits</p>
                        <p>Select and Open a Project from the table</p>
                        {#if lead_annotator}
                            <p>You also have permission to create a new Project</p>
                        {/if}
                    </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler2('project')}
                    {#await pp}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {:then v}
                        {@render boiler4(v)}
                        <Tabs.Root bind:value={models.project.tab} class="w-full">
                            <Tabs.List>
                                <Tabs.Trigger value="info">Project Info</Tabs.Trigger>
                                <Tabs.Trigger value="tasks">Project Tasks</Tabs.Trigger>
                                <Tabs.Trigger value="members">Project Members</Tabs.Trigger>
                            </Tabs.List>
                            <Tabs.Content value="info">
                                {@render boiler5('project', v)}
                            </Tabs.Content>
                            <Tabs.Content value="tasks">
                                <Help {help}>
                                    {#snippet content()}
                                        <div>
                                            <p>Tasks contain Kits</p>
                                            <p>Select and Open a Task from the table</p>
                                            {#if v.project_admin_bool}
                                                <p>You also have permission to create a new Task</p>
                                            {/if}
                                        </div>
                                    {/snippet}
                                </Help>
                                {#if taskpp}
                                    <div class="float-right">
                                        <button class="{btn}" onclick={() => (taskpp = null) || actions.project.get_one('tasks')}>Return to Task list</button>
                                    </div>
                                    {#await taskpp}
                                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                                    {:then vv}
                                        {#if vv.error}
                                            <div>Error: {vv.error}</div>
                                        {:else}
                                            <div class="float-right p-2">
                                                {vv.name} {vv.id}
                                            </div>
                                            <!-- <Task {help} {project_admin} {project_id} {task_id} {...v} {project_users} reload={open} {info} /> -->
                                            <!-- {task_id} {task_index[task_id].name} -->
                                            <Tabs.Root bind:value={models.task.tab} class="w-full justify-center">
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
                                                    {#if models.task.tab == 'info'}
                                                        {#if v.project_admin_bool}
                                                            {@render boiler5('task', vv)}
                                                        {:else}
                                                            <div class="col-3 mx-auto">
                                                                <div>ID: {vv.id}</div>
                                                                <div>Name: {vv.name}</div>
                                                            </div>
                                                        {/if}
                                                    {/if}
                                                </Tabs.Content>
                                                <Tabs.Content value="kits">
                                                    {#if models.task.tab == 'kits'}kits
                                                        <Kits
                                                            {help}
                                                            project_id={v.id}
                                                            task_id={vv.id}
                                                            task_admin={vv.task_admin_bool}
                                                            task_users={vv.members}
                                                        />
                                                    {/if}
                                                </Tabs.Content>
                                                <Tabs.Content value="duals">
                                                    {#if tab == 'duals'}duals
                                                <!-- <Duals
                                                    {help}
                                                    {project_id}
                                                    {task_id}
                                                    task_admin={task_admin_boovv.l}
                                                    {task_users}
                                                    {meta}
                                                /> -->
                                                    {/if}
                                                </Tabs.Content>
                                                <Tabs.Content value="members">
                                                    {@render member_tab('task', vv)}
                                                </Tabs.Content>
                                                <Tabs.Content value="batches">
                                                    {#if tab == 'batches'}batches
                                                <!-- {#if project_admin || lead_annotator || task_admin_bool}
                                                    <KitBatches
                                                        {help}
                                                        {project_id}
                                                        {task_id}
                                                        task_admin={task_admin_bool}
                                                        {task_users}
                                                    />
                                                {:else}
                                                    Permission Denied
                                                {/if} -->
                                                    {/if}
                                                </Tabs.Content>
                                                <Tabs.Content value="nodes">
                                                    {#if tab == 'nodes'}nodes
                                                <!-- {#if project_admin || lead_annotator || task_admin_bool}
                                                    <Nodes
                                                        {project_id}
                                                        {task_id}
                                                    />
                                                {:else}
                                                    Permission Denied
                                                {/if} -->
                                                    {/if}
                                                </Tabs.Content>
                                                <Tabs.Content value="nb">
                                                    {#if tab == 'nb'}nb
                                                <!-- {#if project_admin || lead_annotator || task_admin_bool}
                                                    <NewBatches
                                                        {help}
                                                        {task_id}
                                                        task_admin={task_admin_bool}
                                                        {task_users}
                                                    />
                                                {:else}
                                                    Permission Denied
                                                {/if} -->
                                                    {/if}
                                                </Tabs.Content>
                                            </Tabs.Root>
                                        {/if}
                                    {/await}
                                {:else}
                                    <div class="flex justify-around items-center my-2">
                                        {#if v.project_admin_bool}
                                            <div class="font-semibold">All Tasks</div>
                                        {:else}
                                            <div class="font-semibold">My Tasks</div>
                                        {/if}
                                        {#if models.task.id && models.task.index}
                                            <div>
                                                <button class={buttonVariants({ variant: "secondary" })} onclick={() => actions.task.get_one()}>Open</button>
                                            </div>
                                            {@render boiler7('task')}
                                            {#if v.project_admin_bool}
                                                {@render dialog_delete('task')}
                                            {/if}
                                        {/if}
                                        {#if v.project_admin_bool}
                                            {@render dialog_create('task')}
                                        {/if}
                                    </div>
                                    <Table
                                        indexf={x => models.task.index = x}
                                        columns={[
                                            [ 'ID', 'id', 'col-1' ],
                                            [ 'Task', 'name', 'col-2' ],
                                            [ 'Available Kits', 'available_kit_count', 'col-1' ],
                                            [ 'Source UID', 'source_uid', 'col-1' ]
                                        ]}
                                        rows={v.tasks}
                                        selectedf={(x, y) => (models.task.id = x) && set_style(y)}
                                    />
                                {/if}
                            </Tabs.Content>
                            <Tabs.Content value="members">
                                {@render member_tab('project', v)}
                            </Tabs.Content>
                        </Tabs.Root>
                    {/await}
                {:else}
                    {@render boiler3("project", admin, lead_annotator)}
                    <Table
                        indexf={x => models.project.index = x}
                        columns={[
                            [ 'ID', 'id', 'col-1' ],
                            [ 'Project', 'name', 'col-2', 'html' ],
                            [ 'Task Count', 'task_count', 'col-1' ]
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.project.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="browse">
        {#if tab == 'browse'}
    <Browse
        {help}
        {admin}
        {portal_manager}
        {project_manager}
        {p}
        bind:this={browsex}
    />
        {/if}
    </Tabs.Content>
    <Tabs.Content value="kit_types">
        <Help {help}>
            {#snippet content()}
                <div>
                    <p>kit types</p>
                </div>
            {/snippet}
        </Help>
        {#if tab == 'kit_types'}
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler1('kit_type')}
                {:else}
                    {@render boiler3('kit_type', admin, lead_annotator)}
                    <Table
                        indexf={x => models.kit_type.index = x}
                        columns={[
                            [ 'ID', 'id', 'col-1' ],
                            [ 'Name', 'name', 'col-2' ]
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.kit_type.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="features">
        {#if tab == 'features'}
            <Help {help}>
                {#snippet content()}
                <div>
                    <p>features</p>
                </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler1('feature')}
                {:else}
                    {@render boiler3("feature", admin, lead_annotator)}
                    <Table
                        indexf={x => models.feature.index = x}
                        columns={[
                            [ 'Category', 'category', 'col-1' ],
                            [ 'Feature', 'name', 'col-1' ],
                            [ 'Value', 'value', 'col-1' ],
                            [ 'Label', 'label', 'col-2' ],
                            [ 'Description', 'description', 'col-8' ]
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.feature.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="workflows">
        {#if tab == 'workflows'}
            <Help {help}>
                {#snippet content()}
                <div>
                    <p>workflows</p>
                </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler1('workflow')}
                {:else}
                    {@render boiler3("workflow", admin, lead_annotator)}
                    <Table
                        indexf={x => models.workflow.index = x}
                        columns={[
                            [ 'Name', 'name', 'col-1' ],
                            [ 'Description', 'description', 'col-1' ],
                            [ 'Type', 'type', 'col-1' ]
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.workflow.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="groups">
        {#if tab == 'groups'}
            <Help {help}>
                {#snippet content()}
                <div>
                    <p>groups</p>
                </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler2('group')}
                    {#await pp}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {:then v}
                        {@render boiler4(v)}
                        <Tabs.Root bind:value={models.group.tab} class="w-full">
                            <Tabs.List>
                                <Tabs.Trigger value="info">Group Info</Tabs.Trigger>
                                <Tabs.Trigger value="members">Group Members</Tabs.Trigger>
                            </Tabs.List>
                            <Tabs.Content value="info">
                                {@render boiler5('group', v)}
                             </Tabs.Content>
                            <Tabs.Content value="members">
                                {@render member_tab('group', v)}
                            </Tabs.Content>
                        </Tabs.Root>
                    {/await}
                {:else}
                    {@render boiler3("group", admin, lead_annotator)}
                    <Table
                        indexf={x => models.group.index = x}
                        columns={[
                            [ 'Name', 'name', 'col-1' ],
                            [ 'Description', 'description', 'col-1' ],
                            [ 'Type', 'type', 'col-1' ],
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.group.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="permissions">
        {#if tab == 'permissions'}
    <div class="col-2 mx-auto">
        {#if admin}
            <div>You're an Admin.</div>
            <div><button class="{btn}" onclick={ () => { admin = false; portal_manager = true } }>Set yourself to Portal Manager</button></div>
        {:else if portal_manager}
            <div>You're a Portal Manager.</div>
            <div><button class="{btn}" onclick={ () => { portal_manager = false; project_manager = true; lead_annotator = true } }>Set yourself to Project Manager</button></div>
        {:else if project_manager}
            <div>You're a Project Manager.</div>
            <div><button class="{btn}" onclick={ () => { project_manager = false; lead_annotator = false } }>Set yourself to normal User</button></div>
        {:else}
            You don't have any global permissions.
        {/if}
    </div>
        {/if}
    </Tabs.Content>
</Tabs.Root>

