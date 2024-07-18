<script>
    import Spinner from '../work/spinner.svelte';
    export let p1;
    export let p2;
    export let p3;
    export let m1;
    export let m2;
    export let m3;
</script>

<div class="w-full mx-auto">
    {#if p1}
        {#await p1}
            <Spinner />
            {m1}
        {:then v}
            <!-- adding {v.length} segments -->
            using {v}
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
    {/if}
    <hr>
    {#if p2}
        <!-- svelte-ignore missing-declaration -->
        {#await p2}
            <Spinner />
            {m2}
        {:then v}
            <div> adding {v.ch1.length} segments from channel 1</div>
            {#if v.ch2 && v.ch2.length}
                <div> adding {v.ch2.length} segments from channel 2</div>
            {/if}
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
    {/if}
    <hr>
    {#if p3}
        {#await p3}
            <Spinner />
            {m3}
        {:then v}
            <Spinner />
            <div>{v}</div>
        {:catch e}
            <div>error</div>
            <div>{e}</div>
        {/await}
    {/if}
</div>

<style>
</style>
