<script>
    import Modal from '../modal.svelte'
    import { btn, dbtn } from './buttons'
    import { delete_all, delete_all2 } from './modification1';
    export let waveform;
    const deletem = {
        name: 'delete_all_confirm_modal',
        title: 'Delete ALL segments',
        buttons: [
            [ 'DELETE', dbtn, destroy ],
            [ 'Cancel', btn, null ]
        ],
        start_with_button: false
    };
    function destroy(){
        delete_all();
    }
    const deletem2 = {
        name: 'delete_all_confirm_modal2',
        title: 'Delete ALL lines with stereo docid',
        buttons: [
            [ 'DELETE', dbtn, destroy2 ],
            [ 'Cancel', btn, null ]
        ],
        start_with_button: false
    };
    function destroy2(){
        delete_all2(docids.all);
    }
    const docids = { all: [] };
    let two = false;
    document.querySelectorAll('.Segment').forEach( (x) => {
        let docid = window.$(x).data().value.docid;
        if(docid.match(/:/)){
            two = true;
            if(docids[docid]){
                docids[docid].push(docid);
            }
            else{
                docids[docid] = [ docid ];
            }
            docids.all.push(docid);
        }
        console.log(docids)
    });
    // two = true;
</script>

<style>
</style>


{#if two && !waveform.stereo}
    <Modal {...deletem2} open={true} on:close >
        <div slot=body>
            There seem to be stereo docids in this transcript.  Do you want to delete them all?
        </div>
    </Modal>
{:else}
    <Modal {...deletem} open={true} on:close >
        <div slot=body>
            This will remove ALL segments, are you sure you want to do this?
        </div>
    </Modal>
{/if}
