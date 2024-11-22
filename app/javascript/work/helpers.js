import { toast } from "svelte-sonner";

function selectedff(style){
    let timeout;
    const f = (e) => {
        style(`position: absolute; left: ${e.pageX-20}px; top: ${e.pageY+20}px; z-index: 10`);
        if(timeout){
            clearTimeout(timeout);
        }
        timeout = setTimeout( () => style(null), 2000);
    };
    return f;
}

function flash(data, k){
    let flash_value;
    if(!data){
        toast.error('bad response');
    }
    else if(data.error){
        flash_value = data.error.join(' ');
        toast.error(flash_value);
    }
    else{
        flash_value = "updated " + k + " to " + (data[k] || (data.meta && data.meta[k]) || (data.constraints && data.constraints[k]));
        toast.success(flash_value);
    }
}

function response(data, successf, deletedf){
    let flash_value;
    if(!data){
        toast.error('bad response');
    }
    else if(data.error){
        flash_value = data.error.join(' ');
        toast.error(flash_value);
    }
    else{
        if(data.deleted){
            flash_value = data.deleted;
            if(deletedf) deletedf();
        }
        else{
            flash_value = "created " + data.name;
        }
        toast.success(flash_value);
        if(successf) successf();
    }
}

function ok_reload(data, reload){
  let flash_value;
  if(!data){
    toast.error('bad response');
  }
  else if(data.error){
    flash_value = data.error.join(' ');
    toast.error(flash_value);
  }
  else if(data.deleted){
    flash_value = data.deleted;
    toast.success(flash_value);
  }
  else{
    flash_value = data.ok;
    toast.success(flash_value);
  }
  setTimeout( reload, 1000 );
}

export {
    selectedff,
    flash,
    response,
    ok_reload
}