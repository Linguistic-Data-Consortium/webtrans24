<script>
    import { run } from 'svelte/legacy';

    import { tick } from 'svelte';
    import { patchp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Flash from './flash.svelte'
    // export let admin = false;
    

    /**
     * @typedef {Object} Props
     * @property {any} class_def_id - export let lead_annotator = false;
     * @property {any} id
     * @property {any} name
     */

    /** @type {Props} */
    let { class_def_id, id, name = $bindable() } = $props();

    let p;
    let flash_type = $state(null);
    let flash_value = $state();
    let timeout;
    let first = true;
    function update(x){
        if(first){
            // first = false;
            return;
        }
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout(() => {
            patchp(
                `/class_defs/${class_def_id}`,
                { name: name }
            ).then(
                function(data){
                    if(data.error){
                        flash_type = 'error';
                        flash_value = data.error.join(' ');
                    }
                    else{
                        flash_type = 'success';
                        flash_value = "updated " + data.class_def.name;
                    }
                }
            );
        }, 1000);
    }
    run(() => {
        update(name);
    });
    tick().then( () => first = false );
</script>

<style>
</style>

<Flash {flash_type} {flash_value} />
<div class="col-3 mx-auto">
    <div>ID: {id}</div>
    <form>
        <label>
            Name
            <input type=text bind:value={name}/>
        </label>
    </form>
</div>
