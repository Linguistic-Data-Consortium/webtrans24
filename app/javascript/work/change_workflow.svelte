<script>
    import * as Dialog from "$lib/components/ui/dialog";
    import * as Select from "$lib/components/ui/select";
    import { Label } from "$lib/components/ui/label";
    import { Input } from "$lib/components/ui/input";
    import { Button, buttonVariants } from "$lib/components/ui/button";
    import { getp, patchp } from '../lib/ldcjs/getp';
    import { toast } from "svelte-sonner";
    import Spinner from './spinner.svelte';

    let open = $state(false);
    let p = $state(Promise.resolve({ tasks: [], workflows: [] }));
    let filter = $state('');
    let task_id = $state('');
    let workflow_id = $state('');
    let saving = $state(false);

    // reload every time the dialog opens so the current workflows are accurate
    function opened(x){
        if(!x) return;
        filter = '';
        task_id = '';
        workflow_id = '';
        p = getp('/tasks/workflow_options');
    }
    function task_name(x){
        return x.project ? `${x.project} / ${x.name}` : x.name;
    }
    function find(list, id){
        return list.find(x => String(x.id) == id);
    }
    function matches(tasks){
        const f = filter.trim().toLowerCase();
        if(!f) return tasks;
        return tasks.filter(x => task_name(x).toLowerCase().includes(f));
    }
    function save(){
        if(!task_id || !workflow_id) return;
        saving = true;
        patchp(`/tasks/${task_id}/workflow`, { workflow_id: Number(workflow_id) })
        .then(x => {
            saving = false;
            if(!x)           toast.error('bad response');
            else if(x.error) toast.error(x.error.join(' '));
            else{
                toast.success(x.ok);
                open = false;
            }
        });
    }
</script>

<Dialog.Root bind:open onOpenChange={opened}>
    <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Change Workflow</Dialog.Trigger>
    <Dialog.Content>
        <Dialog.Header>
            <Dialog.Title>Change Workflow</Dialog.Title>
            <Dialog.Description>
                A Workflow controls kit assignment. Pick a Task, then the Workflow it should use.
            </Dialog.Description>
        </Dialog.Header>
        {#await p}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            {#if v.error}
                <div>Error: {v.error}</div>
            {:else}
                <div>
                    <Label for="change_workflow_filter">Filter Tasks</Label>
                    <Input type="text" id="change_workflow_filter" placeholder="Project or task name" bind:value={filter} />
                </div>
                <div>
                    <Label for="change_workflow_task">Task</Label>
                    <Select.Root type="single" bind:value={task_id}>
                        <Select.Trigger id="change_workflow_task">
                            {task_id ? task_name(find(v.tasks, task_id)) : 'Select a Task'}
                        </Select.Trigger>
                        <Select.Content>
                            {#each matches(v.tasks) as x}
                                <Select.Item value={String(x.id)} label={task_name(x)} />
                            {/each}
                        </Select.Content>
                    </Select.Root>
                </div>
                <div>
                    <Label for="change_workflow_workflow">Workflow</Label>
                    <Select.Root type="single" bind:value={workflow_id}>
                        <Select.Trigger id="change_workflow_workflow">
                            {workflow_id ? find(v.workflows, workflow_id).name : 'Select a Workflow'}
                        </Select.Trigger>
                        <Select.Content>
                            {#each v.workflows as x}
                                <Select.Item value={String(x.id)} label={x.name} />
                            {/each}
                        </Select.Content>
                    </Select.Root>
                </div>
                {#if task_id}
                    <div class="text-sm">
                        Current workflow: {find(v.tasks, task_id).workflow || 'none'}
                    </div>
                {/if}
                <Dialog.Footer>
                    <Button variant="secondary" disabled={!task_id || !workflow_id || saving} onclick={save}>
                        {saving ? 'Saving...' : 'Save'}
                    </Button>
                </Dialog.Footer>
            {/if}
        {/await}
    </Dialog.Content>
</Dialog.Root>
