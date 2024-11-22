<script>
    import { run } from 'svelte/legacy';

    import { tick } from 'svelte';
    import { patchp } from '../lib/ldcjs/getp';
    import { toast } from "svelte-sonner";
    import Spinner from './spinner.svelte';
    let {
        id,
        is_owner = $bindable(),
        is_admin = $bindable(),
        refresh
    } = $props();
    let p;
    let timeout;
    let first = true;
    function update(x){
        if(first){
            // first = false;
            return;
        }
        patchp(
            `/project_users/${id}`,
            x
        ).then(
            function(data){
                let flash_value;
                if(!data){
                    toast.error('bad response');
                }
                else if(data.error){
                    flash_value = data.error.join(' ');
                    toast.error(flash_value);
                    refresh();
                }
                else{
                    flash_value = data.ok;
                    toast.success(flash_value);
                    refresh();
                    // if(data.updated.hasOwnProperty('owner')) is_owner = data.updated.owner;
                    // if(data.updated.hasOwnProperty('admin')) is_admin = data.updated.admin;
                    // if(data.updated) refresh({ id, ...data.updated });
                }
            }
        );
    }
    run(() => {
        update({ owner: is_owner });
    });
    run(() => {
        update({ admin: is_admin });
    });
    tick().then( () => first = false );
</script>

<style>
</style>

{#if p}
    {#await p}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {/await}
{/if}
<div>
    <form class="flex flex-column justify-center space-evenly gap-y-1.5 w-1/2">
        <label>
            <input type=checkbox bind:checked={is_owner}/>
            Owner
       </label>
        <label>
            <input type=checkbox bind:checked={is_admin}/>
            Admin
       </label>
    </form>
</div>
