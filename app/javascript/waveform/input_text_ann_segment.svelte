<script>
    import { tick } from 'svelte';
    import { createEventDispatcher } from 'svelte';
    const dispatch = createEventDispatcher();
    import { fmap_helper } from './keyboard_helper'
    import { x as map } from './keys_input'
    import { change_value } from './modification1';
    export let node_id;
    export let name;
    export let key = null;
    export let disabled = false;
    export let readonly;
    export let readonly_text;
    export let focus;
    export let transcription;
    let unused = transcription;
    let sel = `#node-${node_id} .${name}`;
    let value;
    let iid;
    if(window.ldc.nodes){
        value = readonly_text;
        iid = node_id + 2;
        if(readonly) console.log('readonly ' + readonly_text);
        tick().then( () => first = false );
    }
    else{
        window.wait_for(sel, () => {
            let d = window.gdata(sel);
            iid = d.meta.id;
            value = d.value;        
            if(value){
                value = value.value;
            };
            if(readonly) value = readonly_text;
            if(readonly) console.log('readonly ' + readonly_text);
            tick().then( () => first = false );
            tick().then( () => dispatch('init', value) );
        });
    }
    function patch(k, v, e){
        if(timeout) timeout = false;
        // if(window.ldc.nodes) transcription.nodes.get('Transcription').node_value.set( { value: value } );
        change_value(iid, value, () => dispatch(e, value) );
    }
    let first = true;
    let timeout;
    function update(x){
        if(first){
            return;
        }
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => patch( key, value, 'changelite' ) , 1000 );
    }
    $: update(value);
    export function change(v){
        value = v;
    }
    // tick().then( () => first = false );
    function blur(){
        if(timeout){
            clearTimeout(timeout);
            patch( key, value, 'change' );
        }
    }
    function keydown(e){
        const userf = fmap_helper(false, null, e, map);
        if(userf){
            dispatch('userf', { userf: userf, e: e } )
        }
    }
    function init(x){
        if(focus) x.focus();
    }
    if(readonly) value = readonly_text;
</script>

<style>
    input {
        border-width: 0px;
        border: none;
    }
</style>

<input
    class="ann-segment pl-1 p-0 w-full text-sm focus:ring-2 focus:ring-red-500 flex-1 block rounded { value == "REDACTED" ? "bg-red-500" : ""}"
    type=text
    bind:value={value}
    {disabled}
    {readonly}
    on:blur={blur}
    on:keydown={keydown}
    use:init
/>
