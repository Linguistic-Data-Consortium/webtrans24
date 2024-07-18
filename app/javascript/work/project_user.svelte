<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { patchp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Flash from './flash.svelte';
    import Spinner from './spinner.svelte';
    export let id;
    export let is_owner;
    export let is_admin;
    let p;
    let flash_type;
    let flash_value;
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
                if(data.error){
                    flash_type = 'error';
                    flash_value = data.error.join(' ');
                    dispatch('refresh');
                }
                else{
                    flash_type = 'success';
                    flash_value = data.ok;
                    if(data.updated.hasOwnProperty('owner')) is_owner = data.updated.owner;
                    if(data.updated.hasOwnProperty('admin')) is_admin = data.updated.admin;
                    if(data.updated) dispatch('refresh', { id, ...data.updated });
                }
            }
        );
    }
    $: update({ owner: is_owner });
    $: update({ admin: is_admin });
    tick().then( () => first = false );
</script>

<style>
</style>

<Flash {flash_type} {flash_value} />
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
