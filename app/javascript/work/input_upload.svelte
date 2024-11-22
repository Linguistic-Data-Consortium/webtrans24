<script>
    import { btn } from "./buttons"
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Spinner from './spinner.svelte'
    let {
        partial,
        key,
        value,
        label
    } = $props();
    let pp = $state();
    let path = "/sources/get_upload";
    if(partial){
        path += `?partial=${partial}`
    }
    if(key){
        path += `&${key}=${value}`;
    }
    pp = getp(path);
    pp.then( () => sourcefile() );
</script>

<style>
</style>

<details>
    <summary class="{btn}">
        {#if label}
            {label}
        {:else}
            Upload / Preview
        {/if}
    </summary>
    <div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="m-3">
                {@html v.html}
            </div>
        {/await}
    </div>
</details>
