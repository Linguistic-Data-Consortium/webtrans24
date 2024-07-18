<script>
    import InputText from './input_text.svelte'
    export let help = false
    export let admin = false;
    export let lead_annotator = false;
    let unused2 = help && admin && lead_annotator;

    export let id;
    export let category;
    export let name;
    export let value;
    export let label;
    export let description;
    export let feature_id;
    export let created_at;
    export let updated_at;
    let unused = feature_id && created_at && updated_at;

    let url = `/features/${id}`;
</script>

<style>
</style>

<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form on:submit|preventDefault={()=>null}>
        <InputText {url} label=Category key=category value={category} />
        <InputText {url} label=Name key=name value={name} />
        <InputText {url} label=Value key=value value={value} />
        <InputText {url} label=Label key=label value={label} />
        <InputText {url} label=Description key=description value={description} textarea={true} />
    </form>
</div>
