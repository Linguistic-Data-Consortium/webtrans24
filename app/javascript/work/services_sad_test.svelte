<script>
    import { getp, postp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.10/src/getp.js'
    import { getSignedUrlPromise } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.10/src/aws_helper.js'
    export function sb(){ sp = getp(base) }
    // sp = getp(base + '/schema/sad.schema.json');
    // sp = ldc_nodes.getp_simple(base + '/schema/sad.schema.json');
    // sp.then((x) => { console.log('pppppp'); console.log(x) });
    // let urls = window.gdata('.Root').resources.urls;
    
    /**
     * @typedef {Object} Props
     * @property {any} url - let url = Object.keys(urls)[0];
     */

    /** @type {Props} */
    let { url } = $props();
    getSignedUrlPromise('coghealth', url).then( (fn) => get1(fn) );
    // url = 'https://coghealth.s3.amazonaws.com/' + url;
    // get1(url);
    let service_promise = $state();
    let output_promise = $state();
    function get1(fn){
        const o = { type: 'sad', data: { audio: fn } };
        const set_sp = (x) => service_promise = x;
        const set_op = (x) => output_promise = x;
        get_promises(set_sp, set_op, o);
    }
    const base = 'https://hlt.ldcresearch.org';
    function get_promises(set_sp, set_op, o){
        let service_promise;
        let output_promise;
        let interval;
        const get_service_promise = (o) => {
            service_promise = postp(base + '/promises', o);
            set_sp(service_promise);
            service_promise.then( (o) => {
                interval = setInterval( () => get_output_promise(o), 1000);
            } );
        };
        const get_output_promise = (o) => {
            service_promise = getp(base + '/promises/' + o.id);
            set_sp(service_promise);
            service_promise.then( (o) => {
                if(o.status == 'resolved'){
                    clearInterval(interval);
                    output_promise = getp(o.data[0].output).then( (x) => JSON.parse(x) );
                    set_op(output_promise);
                    console.log('done');
                }
                else{
                    console.log('waiting');
                    console.log(o)
                }
            } );
        };
        get_service_promise(o);
    }
</script>

<style>
</style>

<pre>
    {#if service_promise}
        {#await service_promise}
            loading
        {:then value}
            <!-- <JSONTree {value} /> -->
            {JSON.stringify(value, null, 2)}
        {/await}
    {/if}
</pre>
<pre>
    {#if output_promise}
        {#await output_promise}
            loading
        {:then value}
            <!-- <JSONTree {value} /> -->
            {JSON.stringify(value, null, 2)}
        {/await}
    {/if}
</pre>
