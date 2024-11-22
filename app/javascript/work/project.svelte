<script>
    import * as Tabs from "$lib/components/ui/tabs";
    import Tasks from './tasks.svelte';
    import Members from './project_users.svelte';
    import InputText from './input_text.svelte';

    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} project_id
     * @property {any} goto_task
     * @property {any} id
     * @property {any} name
     * @property {any} project_owner_bool
     * @property {any} project_admin_bool
     * @property {any} tasks
     * @property {any} project_users
     * @property {any} [info]
     * @property {any} reload
     */

    /** @type {Props} */
    let {
        help,
        admin = false,
        lead_annotator = false,
        project_id,
        goto_task,
        id,
        name,
        project_owner_bool,
        project_admin_bool,
        tasks,
        project_users,
        info = null,
        reload
    } = $props();
    let unused = admin && lead_annotator && info;
    // let page = 2;
    // function pagef(e){ page = e.detail }
    // let pages = [
    //     [ 'Project Info', 'all', 'project attributes' ],
    //     [ 'Tasks', 'all', 'tasks, kits' ],
    //     [ 'Project Members', 'admin', 'members of this project' ]
    // ];
    let url = `/projects/${project_id}`;
    let tab = $state('tasks');
    function tabs(){}
</script>

<style>
</style>

<!-- <PageTabs {help} {pages} {page} on:page={pagef} admin={project_admin_bool} /> -->

<Tabs.Root bind:value={tab} class="w-full justify-center" onValueChange={tabs}>
    <Tabs.List>
        <Tabs.Trigger value="info">Project Info</Tabs.Trigger>
        <Tabs.Trigger value="tasks">Tasks</Tabs.Trigger>
        <Tabs.Trigger value="members">Project Members</Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value="info">
        {#if tab == 'info'}
    {#if project_owner_bool}
        <div class="col-3 mx-auto">
            <div><span class="font-bold">ID:</span> {id}</div>
            <div>
                <InputText {url} label=Name key=name value={name} />
            </div>
        </div>
    {:else}
        <div class="col-3 mx-auto">
            <div><span class="font-bold">ID:</span> {id}</div>
            <div><span class="font-bold">Name:</span> {name}</div>
        </div>
    {/if}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="tasks">
    {#if tab == 'tasks'}
    <Tasks
        {help}
        {project_id}
        project_admin={project_admin_bool}
        {tasks}
        {project_users}
        {reload}
        {goto_task}
    />
    {/if}
    </Tabs.Content>
    <Tabs.Content value="members">
        {#if tab == 'members'}
    <Members
        {project_id}
        project_owner={project_owner_bool}
        project_admin={project_admin_bool}
        {project_users}
        {reload}
    />
        {/if}
    </Tabs.Content>
</Tabs.Root>
