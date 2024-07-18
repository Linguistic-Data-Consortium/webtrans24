<script>
    import { btn } from './buttons'
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    // export let admin = false;
    // export let lead_annotator = false;
    // export let class_def_id;
    // export let name;
    // export let project_id;
    export let task_id;


    let url = `/xamespaces?task_id=${task_id}`;

    let p = getp(`/xamespaces/0?task_id=${task_id}&output=one`);

    let tables = [ 'annotations', 'nodes' ];
    p.then( (x) => {
        console.log(x)
        for(const k of x){
            // tables.push([k, getp(url + '?output=' + k)]);
            tables.push(k);
        }
        tables = tables;
    } );
    let columns = [];
    let rows = [];
    let defined = '';
    let pp = Promise.resolve();
    function fill(t, c){
        // table = t;
        const cc = c ? '&count=true' : ''
        const kitq = kit_uid ? `&kit_uid=${kit_uid}` : '';
        // pp = getp(url + '?output=' + t + cc).then( (x) => {
        pp = getp(url + '&output=' + t + cc + kitq).then( (x) => {
            columns = x.columns
            // .filter( (x) => !x.match(/iid$/))
            .map( (x) => [ x, x, 'col-1' ] );
            rows = x.rows;
            console.log(x);
            count = x.count;
            defined = x.defined;
        } );
    }
    let count = 0;
    let table = '';
    let checkp = Promise.resolve();
    let trees_ok = 0;
    let trees_notok = 0;
    function check(t){
        checkp = getp(url + '?output=' + t + '&check=true').then( (x) => {
            trees_ok = x.ok;
            trees_notok = x.notok;
        } );
    }
    // fill('annotations', false);
    let kit_uid;
</script>

<style>
</style>

<div class="col-12 mx-auto">
    <span>kit uid:</span>
    <span><input class="w-48 inline" bind:value={kit_uid} /></span>
    {#each tables as t}
        <button class="{btn}" on:click={ () => fill(t, false) }>{t}</button>
    {/each}
</div>
<hr>
<!-- <div class="col-12 mx-auto p-3">
    {#if count && table}
        <div>{count} rows in {table}</div>
        <div>trees should have these columns {defined}</div>
        <div><button class="{btn}" on:click={ () => check(table) }>check {table}</button></div>
        {#await checkp}
            checking...
        {:then v}
            <div>{trees_ok} trees ok, {trees_notok} trees not ok</div>
        {/await}
        <div><button class="{btn}" on:click={ () => fill(table, false) }>load {table}</button></div>
    {/if}
</div>
<hr> -->

{#await pp}
    loading...
{:then}
    <Table {columns} {rows} use_filter={true} key_column=id height=400 />
{/await}    

