<script>
    import { preventDefault } from 'svelte/legacy';

    import InputText from './input_text.svelte'
    import InputSelect from './input_select.svelte'
    export const admin = false;
    export const lead_annotator = false;

    let {
        id,
        name,
        description,
        type,
        types
    } = $props();

    let url = `/workflows/${id}`;
    console.log('check');
</script>

<style>
</style>

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form onsubmit={preventDefault(()=>null)}>
        <InputText {url} label=Name key=name value={name} />
        <InputText {url} label=Description key=description value={description} textarea={true} />
        <InputSelect {url} label=Type key=type value={type} values={types} />
    </form>
</div>
