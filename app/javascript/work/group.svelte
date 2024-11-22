<script>
    import { preventDefault } from 'svelte/legacy';

    import PageTabs from './page_tabs.svelte'
    import Members from './group_users.svelte'
    import InputText from './input_text.svelte'
    
    

    /**
     * @typedef {Object} Props
     * @property {boolean} [admin] - export let help;
     * @property {any} id - export let lead_annotator = false;
     * @property {any} name
     * @property {any} group_users
     * @property {any} reload
     */

    /** @type {Props} */
    let {
        admin = false,
        id,
        name,
        group_users,
        reload
    } = $props();


    let url = `/groups/${id}`;

    let page = $state(2);
    function pagef(e){ page = e.detail }
    let pages = [
        [ 'Group Info', 'all', 'task attributes' ],
        [ 'Group Members' , 'admin', 'members of this task' ]
    ];
</script>

<style>
</style>

<PageTabs {pages} {page} on:page={pagef} admin={admin} />

{#if page == 1}
    <div class="col-3 mx-auto">
        <div>ID: {id}</div>
        <form onsubmit={preventDefault(()=>null)}>
            <InputText {url} label=Name key=name value={name} />
        </form>
    </div>
{:else if page == 2}
    <Members
        group_id={id}
        {group_users}
        {reload}
    />
{/if}
