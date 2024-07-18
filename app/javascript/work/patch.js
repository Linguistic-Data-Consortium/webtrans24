import { patchp } from 'https://cdn.jsdelivr.net/gh/Linguistic-Data-Consortium/ldcjs@0.0.9/src/getp.js'
function make_patch(url, error, success){
  return (k, v) => {
    let x = {};
    x[k] = v;
    patchp( url, x ).then(
      function(data){
        if(data.error) error(data.error.join(' '));
        else           success("updated " + k + " to " + (data[k]), data[k]);
      }
    );
  };
}
export { make_patch }
