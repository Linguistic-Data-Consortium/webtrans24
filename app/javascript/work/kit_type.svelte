<script>
    import { preventDefault } from 'svelte/legacy';

    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    import InputCheckbox from './input_checkbox.svelte'

    
    /**
     * @typedef {Object} Props
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} kit_type_id
     * @property {any} id
     * @property {any} name
     * @property {any} node_class_id
     * @property {any} node_classes
     * @property {any} constraints - export let feature_files;
     * @property {any} features
     */

    /** @type {Props} */
    let {
        admin = false,
        lead_annotator = false,
        kit_type_id,
        id,
        name,
        node_class_id,
        node_classes,
        constraints,
        features
    } = $props();

    let url = `/kit_types/${kit_type_id}`;
    let node_class = $state();
    for(let x of node_classes){
        if(x.id == node_class_id){
            node_class = x;
            break;
        }
    }

    let constraintb = $state({});
    for(let x of features){
        if(x.name == x.value){
            constraintb[x.name] = constraints[x.name] == x.name;
        }
        else{
            constraintb[x.name] = constraints[x.name];
        }
    }
</script>

<style>
</style>

<div class="w-1/2 mx-auto">
    <div>ID: {id}</div>
    <form onsubmit={preventDefault(()=>null)}>
        <InputText {url} label=Name key=name value={name} />
        <InputSelect {url} label=Namespace key="node_class_id" value={node_class} values={node_classes} att=name />
        {#each features as x}
            {#if x.name == x.value}
                <InputCheckbox {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" />
            {:else if x.value == 'comma'}
                <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" split="," />
            {:else}
                <InputText {url} label={x.label} key={x.name} value={constraintb[x.name]} meta="constraints" />
            {/if}
        {/each}
    </form>
</div>
