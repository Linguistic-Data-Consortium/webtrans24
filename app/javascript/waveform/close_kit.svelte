<script>
    import Modal from '../modal.svelte'
    import { cbtn, dbtn } from './buttons'
    import { event } from '../guides/guide';
    import { done, skip, broken } from './modification1';

    let audit;
    let done_comment;
    let broken_comment;
    function donef(){
        let c = null;
        if(done_comment && done_comment.length) c = done_comment;
        done(c);
    }
    function brokenf(){
        let c = null;
        if(broken_comment && broken_comment.length) c = broken_comment;
        broken(c);
    }
    const modal = {
        title: 'Close Transcript, Move to Next File',
        width: 'w-96',
        buttons: [
        ]
    };
</script>

<style>
</style>

<Modal {...modal}>
    <div slot=summary>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
        </svg>
    </div>
    <div slot=body>
        <!-- <ModalHeader title="Close Transcript, Move to Next File" /> -->
        <div class="overflow-auto">
            <div class="overflow-auto">
                <button class="{cbtn} w-full mb-2" on:click={donef} use:event.dispatch={'drew_done'}>Done</button>
                <textarea
                  class="mb-2 focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                  bind:value={done_comment}
                  placeholder="comment (optional)"
                />
                <hr class="mb-2">
                <div>Was there a problem with this file?</div>
                <div class="m-2">
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    type=radio
                                    bind:group={audit}
                                    value=skip
                                />
                                Skip
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="form-group-header">
                            <label>
                                <input
                                    class="focus:ring-indigo-500 focus:border-indigo-500 h-4 w-4 border-gray-300"
                                    type=radio
                                    bind:group={audit}
                                    value=broken
                                />
                                Broken
                            </label>
                        </div>
                    </div>
                </div>
                {#if audit == 'broken' }
                  <textarea
                    class="mb-2 focus:ring-indigo-500 focus:border-indigo-500 flex-1 block w-full rounded-md border-gray-300"
                    bind:value={broken_comment}
                    placeholder="comment (optional)"
                  />
                {/if}
                {#if audit == 'skip'}
                    <div><button class="{dbtn} w-full" data-close-dialog on:click={skip}>Confirm Skip</button></div>
                {/if}
                {#if audit == 'broken'}
                    <div><button class="{dbtn} w-full" data-close-dialog on:click={brokenf}>Confirm Broken</button></div>
                {/if}
            </div>
        </div>
    </div>
</Modal>
