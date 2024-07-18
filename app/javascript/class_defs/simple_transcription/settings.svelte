<script>
    import { onMount, onDestroy } from 'svelte'
    import { settings } from './stores'
    let h = {};
    // each one needs to be saved in save_settings in settings.js
    const all = [
        [ 'open', 'q' ],
        [ 'sections_open', 'a' ],
        [ 'spectrogram_open', 'b' ],
        [ 'experimental', 'x' ]
    ];
    function refocus(){
        document.getElementsByClassName('keyboard')[0].focus();
    }
    let help;
    onMount( () => {
        if(help) help.focus();
    } );
    let a = [];
    function keydown(e){
        for( let y of all ){
            let k = y[0];
            let v = y[1];
            if(e.key == v){
                settings.update( (x) => { x[k] = !x[k]; return x } );
            }
        }
        if(e.key == 'q') refocus();
    }
    
    const unsubscribe = settings.subscribe( (x) => {
        for( let y of all ){
            let k = y[0];
            let v = y[1];
            h[k] = x[k];
        }
    });
    onDestroy( () => unsubscribe() );
</script>

<style>
</style>

<!-- svelte-ignore a11y-no-noninteractive-tabindex -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div bind:this={help} class="grid grid-cols-2 gap-4 p-4" tabindex="0" on:keydown={keydown} >
    {#each all as x}
        <div class="flex">
            <div class="w-4 font-sans font-semibold uppercase text-gray-300">{x[1]}</div>
            <div class="{h[x[0]] ? 'bg-green-100': ''}">{x[0]}</div>
        </div>
    {/each}
</div>
