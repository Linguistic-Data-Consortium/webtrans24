<script>
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { onMount } from 'svelte';
    const a = [
        'Waveform',
        'Text Input',
        'Playback',
        'Services',
        'Open Guidelines'
    ];
    let help;
    onMount( () => {
        help.focus();
    } );
    let keys = {
        "1": "show_help_screen_waveform",
        "2": "show_help_screen_input",
        "3": "show_help_screen_playback",
        // # "4": "show_help_screen_edit",
        "4": "show_help_screen_services",
        "5": "open_guidelines",
        '/': 'special_settings'
    }
    function keydown(e){
        if(Object.keys(keys).includes(e.key)){
            dispatch('show', keys[e.key]);
        }
        else{
            document.querySelector('.keyboard').focus();
            // waveform.help_screen_message('unknown choice');
            dispatch('show', null);
        }
    }
</script>

<style>
</style>

<!-- svelte-ignore a11y-no-noninteractive-tabindex -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div bind:this={help} tabindex=0 on:keydown={keydown} class="p-4">
    <div class="mb-4 ">
        <p>
            When numbered lists appear, pressing the given number makes the given choice.
            Pressing a key that does not correspond to a valid choice will return to the
            waveform, as well as indicate "unknown choice" in the upper right corner.
        </p>
    </div>
    <div>
        <div class="flex justify-around">
            {#each a as x, i}
                <div>{i+1}. {x}</div>
            {/each}
        </div>
    </div>
</div>
