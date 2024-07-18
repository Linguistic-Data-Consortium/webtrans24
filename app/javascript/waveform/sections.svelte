<script>
    import { onDestroy } from 'svelte'
    import Table from '../lib/ldcjs/work/table.svelte';
    import Modal from '../modal.svelte'
    import { btn, dbtn } from './buttons'
    import { sections } from './stores'
    import { settings } from '../class_defs/simple_transcription/stores'
    import { delete_section } from './modification1'
    let secs = [];
    const unsubscribe = sections.subscribe( (x) => secs = x );
    onDestroy( () => unsubscribe() );
    let columns = [
        [ 'Name', 'name', 'col-4' ],
        [ 'Begin', 'beg', 'col-4' ],
        [ 'End', 'end', 'col-4' ]
    ];
    if(window.ldc.obj2.xlass_def_id == 2){
        columns[1][1] = 'begr';
        columns[2][1] = 'endr';
    }
    let table;
    function delete_all(){
        // alert(table.get_selected_key());
        // ns.delete_section_confirm_modal.open_modal()
    }
    function delete_selected(){
        let id = table.get_selected_key();
        if(id){
            delete_section(table.get_selected_key());
        }
        else{
            alert('no section selected');
        }
    }
    const h = {
        name: 'delete_section_confirm_modal',
        title: 'Delete Section',
        h: 'Delete the selected section?',
        buttons: [
            [ 'DELETE', dbtn, delete_selected ],
            [ 'Cancel', btn, null ]
        ]
    };
    let section_name = 'none';
    // that.delete_section_confirm_modal = new Modal h
    // that.delete_section_confirm_modal.init()
    function close(){
        settings.update( (x) => { 
            x.sections_open = false;
            return x;
        } );
    }
</script>

<style>
</style>

<div class="sections">
    <div class="flex justify-around m-2">
        <!-- <button class="btn btn-danger float-right mx-2"
            on:click={delete_all} title="Delete All">
            <i class="fa fa-trash"></i>
            <i class="fa fa-list"></i>
        </button> -->
        <button class="{btn}" on:click={close}>Close</button>
        <Modal {...h}>
            <div slot="summary">Delete Section</div>
            <!-- <div slot=body>{section_name}</div> -->
        </Modal>
    </div>
    <Table bind:this={table} {columns} rows={secs} use_filter={true} key_column=list_item_id />
</div>
