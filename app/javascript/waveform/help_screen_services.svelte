<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    let help;
    onMount( () => {
        help.focus();
    } );
    let keys = {
        '1': "add_sad",
        '2': "add_asr"
    }
    function keydown(e){
        if(Object.keys(keys).includes(e.key))
            dispatch('service', keys[e.key]);
        else
            dispatch('show', null);
    }
</script>

<style>
</style>

<!-- svelte-ignore a11y-no-noninteractive-tabindex -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
<ol>
<li>
1. SAD
</li>
    <li>
    2. ASR
    </li>
</ol>
</div>

