<script>
  import { btn } from "./work/buttons"
  import { getp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.3/src/getp.js'
  import Spinner from './work/spinner.svelte'
  let header = false;
  function d(){
    document.getElementsByClassName('keyboard')[0].focus();
  }
  function ee(){}
  function e(){
    header = false;
  }
  let header_input;
  function open(){
    header = true;
  }
  const data = document.getElementById('headerdata').dataset;
  function unlock(){
    getp(`/kits/${data.kitid}/unlock_tree`).then( (x) => {
      console.log(x);
      window.location.reload();
    } );
  }
</script>

<button class="fixed top-0 right-0 text-white" on:click={open}>header</button>

{#if header}
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="fixed top-0 h-10 bg-white right-0 z-30 w-10 bg-green-300" on:click={e} on:keydown={ee}></div>
    <div class="fixed top-0 h-10 bg-white left-0 right-0 z-20">
      <input bind:this={header_input} type=text class="bg-green-300 w-full border-none text-center focus:ring-0 text-white text-4xl"/>
    </div>
      <!-- <button class="fixed top-0 h-10 bg-white right-20" on:click={d}>d</button> -->
      <button class="fixed top-0 h-10 bg-white right-10" on:click={e}>e</button>
{:else}
    <div class="Header-item mr-10 p-4"><a href="/">Home</a></div>
    <div class="Header-item mr-10 p-4"><a href="/documentation">Documentation</a></div>
    <div class="Header-item mr-10 p-4"><a id="logout" href="/logout2" data-method="delete" rel="nofollow">Sign out</a></div>
    <div class="Header-item mr-10 p-4">
      <div id="current_user_name" class="Label Label--green">{data.user}</div>
    </div>
    {#if data.kitid}
      <div class="Header-item mr-10 p-4">
        <div id="kit_uid" class="Label Label--green">{data.kituid}</div>
      </div>
      <div class="Header-item mr-10 p-4">
        <div id="task_name" class="Label Label--green"></div>
      </div>
      {#if data.locked}
        <div class="Header-item mr-10 p-4">
          <button class="{btn}" on:click={unlock}>unlock</button>
        </div>
      {/if}
      <div id="spinner">
        <Spinner />
      </div>
    {/if}
{/if}
