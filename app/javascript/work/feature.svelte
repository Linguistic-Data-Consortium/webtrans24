<script>
    import { preventDefault } from 'svelte/legacy';

    import InputText from './input_text.svelte'

    /**
     * @typedef {Object} Props
     * @property {boolean} [help]
     * @property {boolean} [admin]
     * @property {boolean} [lead_annotator]
     * @property {any} id
     * @property {any} category
     * @property {any} name
     * @property {any} value
     * @property {any} label
     * @property {any} description
     * @property {any} feature_id
     * @property {any} created_at
     * @property {any} updated_at
     */

    /** @type {Props} */
    let {
        help = false,
        admin = false,
        lead_annotator = false,
        id,
        category,
        name,
        value,
        label,
        description,
        feature_id,
        created_at,
        updated_at
    } = $props();
    let unused = feature_id && created_at && updated_at;

    let url = `/features/${id}`;
</script>

<style>
</style>

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form onsubmit={preventDefault(()=>null)}>
        <InputText {url} label=Category key=category value={category} />
        <InputText {url} label=Name key=name value={name} />
        <InputText {url} label=Value key=value value={value} />
        <InputText {url} label=Label key=label value={label} />
        <InputText {url} label=Description key=description value={description} textarea={true} />
    </form>
</div>
