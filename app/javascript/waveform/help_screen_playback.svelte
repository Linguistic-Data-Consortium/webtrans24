<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    import HelpScreenPlaybackHtml from './help_screen_playback_html.svelte';
    let help;
    onMount( () => {
        help.focus();
    } );
    function keydown(e){
        dispatch('show', null);
    }
</script>

<style>
</style>

<!-- svelte-ignore a11y-no-noninteractive-tabindex -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4 h-96 overflow-auto">
    <HelpScreenPlaybackHtml />
</div>
