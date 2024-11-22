<script>
    import { flash } from './helpers';
    export let label;
    export let key;
    export let value;
    export let url;
    export let meta;
    export let wrap;
    const id = Math.random().toString(36).substring(2);
    function patch(k, v){
        if(!url){
            return;
        }
        let x = {};
        if(meta == 'meta'){
            x.meta = {};
            x.meta[k] = v;
        }
        else if(meta == 'constraints'){
            x.constraints = {};
            x.constraints[k] = v;
        }
        else{
            x[k] = v;
        }
        if(wrap){
            const y = {};
            y[wrap] = x;
            x = y;
        }
        patchp( url, x ).then(
            x => flash(x, k)
        );
    }
    patch( key, value );
</script>

<div class="form-group {flash_type ? flash_type + "ed" : ''}">
    <div class="form-group-header">
        <label for="input-{id}">
            {label}
        </label>
    </div>
</div>
