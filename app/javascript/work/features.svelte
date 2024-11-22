<script>
    import { preventDefault } from 'svelte/legacy';

    import { btn, cbtn } from "./buttons"
    import { getp, postp, deletep } from '../lib/ldcjs/getp';
    import Help from './help.svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import Feature from './feature.svelte'
    import InputText from './input_text.svelte'
    import Spinner from './spinner.svelte'
    import { selectedff } from './helpers';
    import { toast } from "svelte-sonner";
    /**
     * @typedef {Object} Props
     * @property {any} help
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     */

    /** @type {Props} */
    let { help, admin = false, lead_annotator = false } = $props();
    // export let portal_manager = false;
    // export let project_manager = false;
    let category = $state();
    let name = $state();
    let p = $state();
    function get(){ p = getp('/features') }
    get();
    let columns = [
        [ 'Category', 'category', 'col-1' ],
        [ 'Feature', 'name', 'col-1' ],
        [ 'Value', 'value', 'col-1' ],
        [ 'Label', 'label', 'col-2' ],
        [ 'Description', 'description', 'col-8' ]
    ];
    const createm = {
        name: 'create_feature_modal',
        title: 'Create feature',
        h: '',
        buttons: [
            [ 'Create', cbtn, create ]
        ]
    };
    const deletem = {
        name: 'delete_feature_modal',
        b: 'DELETE',
        ff: destroy,
        title: 'Delete feature',
        h: ''
    };
    function response(data){
        let flash_value;
        if(!data){
            toast.error('bad response');
        }
        else if(data.error){
            flash_value = data.error.join(' ');
            toast.error(flash_value);
        }
        else{
            if(data.deleted){
                flash_value = data.deleted;
                feature_id = null;
            }
            else{
                flash_value = "created " + data.name;
            }
            toast.success(flash_value);
            get();
        }
    }
    function create(){
        postp(
            "/features",
            { category: category, name: name }
        ).then(response);
    }
    function destroy(){
        deletep(
            `/features/${feature_id}`
        ).then(response);
    }
    let feature_id = $state();
    let feature_index = $state();
    let pp = $state();
    function open(){
        pp = getp(`/features/${feature_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    let style = $state();
    let selectedf = selectedff(x => style = x);
</script>

<style>
</style>

<Help {help}>
    {#snippet content()}
    <div>
        <p>features</p>
    </div>
    {/snippet}
</Help>

{#await p}
    <div class="mx-auto w-8 h-8"><Spinner /></div>
{:then v}
    {#if pp}
        <div class="float-right">
            <button class="{btn}" onclick={back}>Return to Feature list</button>
        </div>
        {#await pp}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <div class="float-right p-2">
                {v.name}
            </div>
            <Feature {help} {admin} {lead_annotator} {feature_id} {...v} />
        {/await}
    {:else}
        <div class="flex justify-around">
            <div>All features</div>
            {#if feature_id && feature_index}
                <div>
                    <button class="{btn}" onclick={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class="{btn}" onclick={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <Modal {...deletem}>
                        {#snippet summary()}
                        <div>
                            Delete
                        </div>
                        {/snippet}
                        {#snippet body()}
                        <div >
                            This will delete the feature {feature_index[feature_id].name}, are you sure you want to do this?
                        </div>
                        {/snippet}
                    </Modal>
                {/if}
            {:else}
                Select a feature in the table for more options.
            {/if}
            {#if lead_annotator}
                <Modal {...createm}>
                    {#snippet summary()}
                    <div>
                        Create feature
                    </div>
                    {/snippet}
                    {#snippet body()}
                    <div>
                        <form onsubmit={preventDefault(()=>null)}>
                             <InputText label=Category key=category bind:value={category} />
                             <InputText label=Name key=name bind:value={name} />
                        </form>
                    </div>
                    {/snippet}
                </Modal>
            {/if}
        </div>
        <Table bind:selected={feature_id} indexf={x => feature_index = x} {columns} rows={v} use_filter={true} key_column=id height=400 {selectedf} />
    {/if}
{/await}
