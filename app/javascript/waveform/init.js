import { set_ldc, init_nodes } from '../class_defs/helpers/other'
import { active_docid } from '../lib/ldcjs/waveform/stores';
import { mount } from 'svelte';
import Main from '../lib/ldcjs/waveform/main.svelte';
import { getp, postp } from '../lib/ldcjs/getp';
import { refreshToken, s3url, getSignedUrlPromise } from '../lib/ldcjs/aws_helper';
import { fromCognitoIdentity } from "@aws-sdk/credential-provider-cognito-identity";
import { CognitoIdentityClient } from "@aws-sdk/client-cognito-identity";
import { TranscribeClient } from "@aws-sdk/client-transcribe";
import { S3Client, GetObjectCommand, HeadObjectCommand, ListObjectsV2Command, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
function init(ldc){
  refreshToken({
    fromCognitoIdentity,
    CognitoIdentityClient,
    TranscribeClient,
    S3Client,
    GetObjectCommand,
    HeadObjectCommand,
    ListObjectsV2Command,
    PutObjectCommand,
    getSignedUrl
});
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
    set_urls(obj.source.uid).then((o) => {
      ldc.maino = o;
      if(o) active_docid.set(o.wav);
    });
  }
  function set_urls(kk){
    const k = kk.replace(/\s+$/, '');
    const found = s3url(k);
    if(found.bucket) {
        return set_urls3(found, k);
        // .then( (x) => signed_url_for_audio(found.bucket, found.key, urls, x) )
        // .then( () => k );
    }
    else{
        return set_urls2(k);
    }
}
function set_urls3(found, k){
    ldc.resources.bucket = found.bucket;
    const urls = ldc.resources.urls;
    return Promise.resolve( 
        k.match(/wav$/) ? { wav: k } :
        getSignedUrlPromise(found.bucket, found.key)
        .then( getp )
        .then(function(d){

            const o = {};

            // resolve this one in parallel
            if(d.tsv){
                let found = s3url(d.tsv);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'tsv',
                        found_transcript: d
                    };
                });
            }

            // resolve this one in parallel
            if(d.tdf){
                let found = s3url(d.tdf);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'tdf',
                        found_transcript: d
                    };
                });
            }

            // resolve this one in parallel
            if(d.sad_with_aws){
                let found = s3url(d.sad_with_aws);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'sad_with_aws',
                        found_transcript: d
                    };
                });
            }

            if(d.wav){
              o.wav = d.wav;
              return o;
                // active_docid.update( () => d.wav );
                // found = s3url(d.wav);
                // return signed_url_for_audio(found.bucket, found.key, urls, d.wav)
                // .then( (x) => {
                //     o.wav = x.wav;
                //     // o.wav_url = urls[x.wav];
                //     return o;
                // });
            }
            else{
                return o;
            }
            
        })
        .catch( () => alert('error, try refreshing') )
    );
}
function signed_url_for_audio(bucket, key, urls, k) {
  return getSignedUrlPromise(bucket, key)
  .then(function(data){
      urls[k] = data;
  })
  .then( () => { return { wav: k, wav_url: urls[k] } } );
}
function set_urls2(k){
  const urls = ldc.resources.urls;
  if(k.match(/^http/)) urls[k] = k;
  if(!urls[k]) return;
  if(urls[k].substr(0, 2) === 's3'){
      if(urls[k] === 's3'){
          return alert('missing bucket');
      }
      else{
          ldc.resources.bucket = urls[k].replace(/^s3(:\/\/)?/, '').replace(/\/.+/, '');
          const bucket = ldc.resources.bucket;
          let key = k.replace(bucket + '/', '').replace('filename_for_', '');
          if(ldc.resources.original_s3_key) key = ldc.resources.original_s3_key;
          return signed_url_for_audio(bucket, key, urls, k);
          // .then( () => k );
      }
  }
  else{
      return Promise.resolve( { wav: k, wav_url: urls[k] } );
  }
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
    ns.main = mount(Main, {
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
