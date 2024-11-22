<script>
    import { tick } from 'svelte';
    import { patchp } from '../lib/ldcjs/getp';
    import { flash } from './helpers';
    import { btn, cbtn, dbtn } from './buttons'
    import { fi_text } from './form_inputs';
    let key;
    export let value;
    export let url;
    let def;
    $: def = JSON.parse(value);
    const id = Math.random().toString(36).substring(2);
    function patch(k, v){
        if(!url){
            return;
        }
        let x = {};
        x[k] = v;
        patchp( url, x ).then(
            x => flash(x, k)
        );
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
        timeout = setTimeout( () => patch( key, value ) , 1000 );
    }
    $: update(value);
    tick().then( () => {
        first = false;
        if(!value){
            key = 'def';
            value = '{}';
        }
    } );
    let input_value = '';
    function add_list(){
        key = 'def';
        if(!input_value.match(/^\w+$/)){
            alert('only use letters and numbers');
        }
        else if(!input_value.match(/^[A-Z]/)){
            alert('must start with a capital letter');
        }
        else{
            if(!input_value.match(/List$/)) input_value += 'List'
            if(!def.classes) def.classes = {};
            if(!def.classes[input_value]){
                def.classes[input_value] = { children: [] };
                value = JSON.stringify(def);
            }
        }
    }
    $: class_list = Object.keys(def.classes);
    let selected_class;
    function delete_class(){
        key = 'def';
        delete def.classes[selected_class];
        value = JSON.stringify(def);
        selected_class = null;
    }
    let modify_children = false;
    let selected_children;
    function save_children(){
        key = 'def';
        modify_children = !modify_children;
        if(modify_children){
            selected_children = def.classes[selected_class].children.join(' ');
        }
        else{
            let a = [];
            for(const x of selected_children.split(' ')){
                if(!x.match(/^\w+$/)){
                    alert('bad name: ' + x);
                    return;
                }
                else if(!x.match(/^[A-Z]/)){
                    alert('name must start with capital');
                    return;
                }
                else{
                    a.push(x);
                }
            }
            def.classes[selected_class].children = a;
            value = JSON.stringify(def);
        }
    }
</script>

<div class="form-group {flash_type ? flash_type + "ed" : ''}">
    <div class="form-group-body">
        <input
            id="input-{id}"
            class={`form-control ${fi_text}`}
            type="text"
            bind:value={input_value}
            aria-describedby="input-{id}-validation"
        />
        <button class="{cbtn}" on:click={add_list}>add list</button>
        <div>
            {#if modify_children}
                <input
                    id="input-{id}"
                    class={`form-control ${fi_text}`}
                    type="text"
                    bind:value={selected_children}
                    aria-describedby="input-{id}-validation"
                />
            {:else}
                {#each class_list as x}
                    <button class={btn} on:click={() => selected_class = x}>{x}</button>
                {/each}
            {/if}
            {#if selected_class}
                <div>
                    {selected_class}
                    <button class={dbtn} on:click={delete_class}>delete class</button>
                    <button class={modify_children ? cbtn : dbtn} on:click={save_children}>{modify_children ? "save" : "modify"} children</button>
                </div>
                {#if selected_children}
                    <div>
                        {selected_children}
                    </div>
                {/if}
            {/if}
        </div>
        <div>
            {value}
        </div>
    </div>
</div>
