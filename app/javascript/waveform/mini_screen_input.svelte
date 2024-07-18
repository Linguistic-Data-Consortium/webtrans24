<script>
    let invisible = true;
    let title = 'TITLE';
    let input;
    let keyboard;
    let resolvef;
    export function open(h){
        invisible = false;
        title = h.title;
        keyboard = h.keyboard;
        // remove = h.remove;
        setTimeout(function(){
            // document.getElementById('set_new_speaker_input').focus()
            input.focus()
        }, 100);
        return new Promise( (resolve, reject) => resolvef = resolve );
    }
    export function close(){
        invisible = true;
        // document.getElementById('set_new_speaker_input').value = '';
        value = '';
    }
    export function keydown(e){
        const f = keyboard.handle(e, true);
        if(f) f();
    }

    let value = '';
    export function open_helper(h){
      const kb = h.keyboard;
      kb.map = { Enter: 'setf', Escape: 'escape' };
      kb.delegate.setf = function() {
        // id =  $('.crnt .Speaker').data().meta.id
        const v = value;
        document.querySelector('.keyboard').focus();
        close();
        resolvef(v);
      };
      kb.delegate.escape = function() {
        // id =  $('.crnt .Speaker').data().meta.id
        kb.reset();
        close();
        resolvef(null);
      };
      return open(h);
    }
</script>

<style>
</style>

<!-- svelte-ignore a11y-no-noninteractive-tabindex -->
<div class="shadow-xl bg-white border-2 rounded fixed right-24 top-48 opacity-100 z-10" class:invisible tabindex=0>
    <div class="p-2">
        <div class="p-1 text-sm">{title}</div>
        <input bind:this={input} id="set_new_speaker_input" class="pl-1" on:keydown={keydown} bind:value={value} >
        <div class="p-1 text-sm">or ESC to exit</div>
    </div>
</div>
