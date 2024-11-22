<script>
    import { btn } from "./buttons"
    import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import InputUpload from './input_upload.svelte'
    import Spinner from './spinner.svelte'
    import { response } from './helpers';
    
    
    /**
     * @typedef {Object} Props
     * @property {any} data_set_id - export let help;
     * @property {any} assets - export let project_owner = false;
     */

    /** @type {Props} */
    let { data_set_id, assets } = $props();
    let name;
    let title;
    let description;
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'File', 'name', 'col-2' ],
        [ 'Type', 'type', 'col-2' ]
        // [ 'Description', 'description', 'col-4' ]
    ];
    let asset_id = $state();
    let asset_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/assets/${asset_id}`)
    }
    function back(){
        pp = null;
    }
    function reload(e){
        open();
    }
 </script>

<style>
</style>

{#if pp}
    <div class="float-right">
        <button class="{btn}" onclick={back}>Return to file list</button>
    </div>
    {#await pp}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        <div class="float-right p-2">
            {v.name} {asset_id}
        </div>
    {/await}
{:else}
    <div class="flex justify-around">
        <div>All Files</div>
            <InputUpload partial="preview_data_set_files" key="data_set_id" value={data_set_id} label=Preview />
            <InputUpload partial="upload_data_set_files" key="data_set_id" value={data_set_id} label=Upload />
    </div>
    <Table bind:selected={asset_id} indexf={x => asset_index = x} {columns} rows={assets} use_filter={true} key_column=id height=400 />
{/if}
