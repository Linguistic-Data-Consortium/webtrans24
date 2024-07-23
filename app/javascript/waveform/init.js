import { set_ldc, init_nodes } from '../class_defs/helpers/other'
import { active_docid } from '../lib/ldcjs/waveform/stores';
import Main from '../lib/ldcjs/waveform/main.svelte';
import { postp } from '../lib/ldcjs/getp';
function init(ldc){
  const obj = ldc.obj2;
  set_ldc(ldc);
  if(obj.xlass_def_id) init_nodes();
  if(!ldc.resources.urls) ldc.resources.urls = ldc.resources.manifest.urls;
  // keys can be 24 or 28?
  if(obj.source.uid.match(/^\w{24,28}$/)){
    // alert(Object.keys(ldc.resources.urls))
    if(obj.filename == obj.source.uid) obj.filename = `filename_for_${obj.source.uid}`;
    active_docid.update( () => obj.filename );
    ldc.resources.urls[obj.filename] = ldc.resources.urls[obj.source.uid];
    ldc.resources.original_s3_key = obj.source.uid;
    console.log(JSON.stringify(ldc.resources))
    delete ldc.resources.urls[obj.source.uid];
  }
  else{
    active_docid.update( () => obj.source.uid );
  }
  const ns = {
    ldc: ldc,
    namespace: 'SimpleTranscription',
    meta: { id: '00' },
    task_id: obj.task_id
  };
  // ldc.cd = ns;
  // ldc.ns = ns;
  // const k = Object.keys(ldc.resources.urls)[0];
  // let p = set_urls(k);//.then(function(o) {
    // ns.p = p;
    // const url = o.wav;
    // ns.transcript = o.transcript;
    // alert(url)
    const h = {
      ldc: ldc
      // ns: ns,
      // waveform: ns.waveform,
      // data_set_id: obj.data_set_id,
      // kit_id: obj.kit_id
      // source_uid: obj.source.uid
      // urlp: p
    };
    ldc.speakers = new Map();
    ldc.sections = new Map();
    ns.main = new Main({
      target: $('.view')[0],
      props: h
    });
    // ldc.main = ns.main;
    // ns.waveform.component = ns.main;
    // ns.segments = ns.main;
    // ns.waveform.services = window.services_init();
    $('.Speaker').each(function(i, y) {
      ldc.speakers.set($(y).data().value.value, true);
    });
    $('.Section').each(function(i, y) {
      ldc.sections.set($(y).data().value.value, true);
    });
    ns.main.update_segments();


    // $('.Root').on 'change', '.transcript-input', ->
    //     # iid = $(this).closest(".segment").data().iid
    //     # Somehow jQuery's data() object is corrupted (wrong iid when new segment inserted before another one)
    //     iid = $(this).closest(".segment")[0].attributes['data-iid'].value
    //     iid = $("#node-#{iid} .Transcription").data().meta.id
    //     value = $(this).val()
    //     ldc_annotate.add_message iid, 'change', { value: value }
    //     ldc_annotate.submit_form()

    ns.set_section = () => {
      return this.section.set_section();
    };

    const interval = setInterval(function() {
      if(ns.waveform && ns.waveform.duration){
        const oo = {
          kit_uid: obj._id,
          duration: ns.waveform.duration
        };
        postp('/duration', oo).then(function(x) {
          console.log('xx');
          console.log(x);
        });
        clearInterval(interval);
      }
    }, 1000);
  

    // return p;
}

export { init }
