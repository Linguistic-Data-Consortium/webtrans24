<script>
    import { run } from 'svelte/legacy';
    import { tick } from 'svelte';
    import { getp, patchp } from '../lib/ldcjs/getp';
    import { ok_reload } from './helpers';
    import Spinner from './spinner.svelte'
    let {
        id,
        is_admin = $bindable(),
        xstate = $bindable(),
        reload
    } = $props();
    let states = [ null, 'needs_kit', 'has_kit', 'hold', 'paused' ];
    let p = getp(`/task_users/${id}`);
    let timeout;
    let first = true;
    function update(x){
        if(first){
            // first = false;
            return;
        }
        patchp(
            `/task_users/${id}`,
            x
        ).then(
            x => ok_reload(x, reload)
        );
    }
    run(() => {
        update({ admin: is_admin });
    });
    run(() => {
        update({ state: xstate });
    });
    tick().then( () => first = false );
</script>

<style>
</style>

<div>
    <form>
        <label>
            <input type=checkbox bind:checked={is_admin}/>
            Admin
       </label>
        <label for=x>
            State
            {#if states.includes(xstate)}
                <select id="x" bind:value={xstate}>
                    {#each states as x}
                        <option value={x}>{x}</option>
                    {/each}
                </select>
            {:else}
                Error
            {/if}
        </label>
    </form>
    <div class="my-4">
        {#if p}
            {#await p}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                <pre>
                    {v.ok}
                </pre>
            {/await}
        {/if}
    </div>
</div>
