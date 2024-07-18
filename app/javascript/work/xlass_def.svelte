<script>
    import { btn } from './buttons'
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import PageTabs from './page_tabs.svelte';
    import InputText from './input_text.svelte'
    import Def from './input_text_def.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    let help;
    export let admin = false;
    export let lead_annotator = false;
    export let class_def_id;
    export let name;
    export let original_id;
    export let def;

    let page = 2;
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Namespace Info',  'lead_annotator', 'namespace attributes' ],
        [ 'Widgets',         'lead_annotator', 'widgets' ],
        [ 'Output',          'lead_annotator', 'output' ]
    ]

    let url = `/xamespaces/${class_def_id}`;

    let p = getp(url + '?output=one');

    const tables = [];
    p.then( (x) => {
        console.log(x)
        for(const k of x){
            // tables.push([k, getp(url + '?output=' + k)]);
            tables.push(k);
        }
    } );
    let columns = [];
    let rows = [];
    let defined = '';
    let pp = Promise.resolve();
    function fill(t, c){
        table = t;
        const cc = c ? '&count=true' : ''
        pp = getp(url + '?output=' + t + cc).then( (x) => {
            columns = x.columns
            .filter( (x) => !x.match(/iid$/))
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
</script>

<style>
</style>

<PageTabs {help} {pages} {page} on:page={pagef} {admin} {lead_annotator} />

{#if page == 1}
    <div class="col-3 mx-auto">
        <div><span class="font-bold">ID:</span> {class_def_id}</div>
        <div>Original ID: {original_id}</div>
        <form on:submit|preventDefault={()=>null}>
            {name}
            <InputText {url} label=Name key=name bind:value={name} />
        </form>
    </div>
{:else if page == 2}
    <div class="col-3 mx-auto">
        <Def {url} value={def} />
    </div>
{:else if page == 3}
    <div class="col-6 mx-auto">
        {#each tables as t}
            <button class="{btn}" on:click={ () => fill(t, true) }>{t}</button>
        {/each}
    </div>
    <hr>
    <div class="col-12 mx-auto p-3">
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
    <hr>
    {#await pp}
        loading...
    {:then}
        <Table {columns} {rows} use_filter={true} key_column=id height=400 />
    {/await}    
{/if}
