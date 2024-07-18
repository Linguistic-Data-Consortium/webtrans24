<script>
    import { getp, postp, deletep } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from './modall.svelte'
    import Flash from './flash.svelte'
    import XlassDef from './xlass_def.svelte'
    import { btn1, cbtn, dbtn } from './buttons'
    import { fi_text } from './form_inputs';
    export let admin = false;
    export let help = false;
    export let lead_annotator = false;
    export let portal_manager = false;
    const unused = portal_manager && help;
    let name;
    let p;
    function get(){ p = getp('/xamespaces') }
    get();
    let columns = [
        [ 'ID', 'id', 'col-1' ],
        [ 'Name', 'name', 'col-2' ]
        // [ 'Task Count', 'task_count', 'col-1' ]
    ];
    let flash_type = null;
    let flash_value;
    function response(data){
        if(data.error){
            flash_type = 'error';
            flash_value = data.error.join(' ');
        }
        else{
            flash_type = 'success';
            if(data.deleted){
                flash_value = data.deleted;
            }
            else{
                flash_value = "created " + data.name;
            }
            get();
        }
    }
    function create(){
        postp(
            "/xamespaces",
            { name: name }
        ).then(response);
        cdialog.close();
    }
    function destroy(){
        deletep(
            `/xamespaces/${class_def_id}`
        ).then(response);
        ddialog.close();
    }
    let class_def_id;
    let class_def_index;
    let pp;
    function open(){
        pp = getp(`/xamespaces/${class_def_id}`)
    }
    function back(){
        pp = null;
        get();
    }
    // setTimeout(()=>{
    //     // class_def_id = 57;
    //     class_def_id = 561;
    //     open()
    // }, 1000)
    function reload(e){
        open();
    }
    let style;
    let timeout;
    function selected(e){
        style = `position: absolute; left: ${e.detail.pageX+20}px; top: ${e.detail.pageY-10}px; z-index: 10`;
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style = null, 2000);
    }
    p.then( (x) => console.log(x))
    let cdialog;
    let ddialog;
</script>

<style>
</style>

{#await p}
    loading...
{:then v}
    {#if pp}
        <div class="float-right">
            <button class={btn1} on:click={back}>Return to namespace list</button>
        </div>
        {#await pp}
            <div><span>Loading</span><span class="AnimatedEllipsis"></span></div>
        {:then v}
            <XlassDef {admin} {lead_annotator} {class_def_id} {...v} on:reload={reload} />
        {/await}
    {:else}
        <Flash {flash_type} {flash_value} />
        <div class="flex justify-around items-center my-3">
            <div class="font-semibold">All Namespaces</div>
            {#if class_def_id}
                <div>
                    <button class={cbtn} on:click={open}>Open</button>
                </div>
                {#if style}
                    <div {style}>
                        <div><button class={cbtn} on:click={open}>Open</button></div>
                    </div>
                {/if}
                {#if admin}
                    <button class="{dbtn}" on:click={() => ddialog.showModal()}>Delete Namespace</button>
                    <!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
                    <dialog bind:this={ddialog} on:click={(e) => e.target.tagName == 'DIALOG' && ddialog.close()} on:keypress={() => null}>
                        <div>Delete Namespace</div>
                        <div>This will delete the class_def {class_def_index[class_def_id].name}, are you sure you want to do this?</div>
                        <div class="flex mt-3">
                            <button class="{btn1} mr-3" on:click={() => ddialog.close()}>Cancel</button>
                            <button class="{dbtn}" on:click={destroy}>Delete</button>
                        </div>
                    </dialog>
                {/if}
            {/if}
            {#if lead_annotator}
                <button class="{cbtn}" on:click={() => cdialog.showModal()}>Create Namespace</button>
                <!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
                <dialog bind:this={cdialog} on:click={(e) => e.target.tagName == 'DIALOG' && cdialog.close()} on:keypress={() => null}>
                    <div>Create Namespace</div>
                    <div>Name</div>
                    <div><input type="text" class="{fi_text}" bind:value={name}/></div>
                    <div class="flex mt-3">
                        <button class="{btn1} mr-3" on:click={() => cdialog.close()}>Cancel</button>
                        <button class="{cbtn}" on:click={create}>Save</button>
                    </div>
                </dialog>
            {/if}
        </div>
        <Table bind:selected={class_def_id} bind:index={class_def_index} {columns} rows={v} use_filter={true} key_column=id height=400 on:selected={selected} />
    {/if}
{/await}
