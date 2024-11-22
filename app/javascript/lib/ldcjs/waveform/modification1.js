import { add_message, add_message_listitem, submit_form, add_callback, setldc } from './modification2';
import { srcs } from './sources_stores';
import { segments } from './stores';
import { event } from '../../../guides/guide';
import { round_to_3_places } from './times';

let ldc;
function set_ldc(x){
  ldc = x;
  setldc(x);
}

function done(comment){
  add_message('0', 'done', comment);
  submit_form();
}

function broken(comment){
  add_message('0', 'broken', comment);
  submit_form();
}

function skip(){
  add_message('0', 'skip', null);
  submit_form();
}

function change_value(n, v, f){
  add_message(n, 'change', { value: v });
  submit_form();
  if(f) add_callback(f);
}

function change_value_src(n, src, f){
  add_message(n, 'change', src);
  submit_form();
  if(f) add_callback(f);
}

function delete_all(){
  const all = [];
  $('.ListItem').each(function(i, x) {
    all.push($(x).data().meta.id);
  });
  if(ldc.nodes){
    // add_message('0', 'delete_all', null);
    // for(const [k, v] of ldc.segmap){
    for(const [k, v] of ldc.nodes){
      if(v.level == 2) all.push(k);
    }
  }
  delete10(0, all);
}

function delete10(i, all){
  let j = i;
  while(j < i + 10 && j < all.length) add_message(all[j++], 'delete', null);
  submit_form();
  if(j < all.length) add_callback(() => delete10(j, all));
}

function delete_all2(all, f){
  $('.ListItem').each(function(i, x) {
    let docid = $(x).find('.Segment').data().value.docid;
    if(all.includes(docid)){
      add_message($(x).data().meta.id, 'delete', null);
      console.log(`delete ${docid}`);
    }
  });
  submit_form();
  if(f) add_callback(f);
}

function delete_all_sections(f){
  $('.SectionListItem').each(function(i, x) {
    add_message($(x).data().meta.id, 'delete', null);
  });
  submit_form();
  if(f) add_callback(f);
}

function delete_last_section(f){
  let last = null;
  $('.SectionListItem').each(function(i, x) {
    let id = $(x).data().meta.id;
    if (Number(id) > Number(last)) {
      last = id;
    }
  });
  if(last){
    add_message(last, 'delete', null);
    submit_form();
    if(f) add_callback(f);
  }
}

function create_test_segment(waveform, f){
  const list_selector = '.SegmentList';
  const audio_path = 'new.Segment';
  const span = {
    offset: 1.0,
    length: 1.0
  };
  add_audio_to_list(list_selector, audio_path, span);
  submit_form();
  if(f) add_callback(f);
}

function split_segment_at_cursor(cursortime, split_line_margin, f) {
  if(ldc.crnt){
    // id = $('.active-transcript-line').attr 'id'
    let data;
    let seg;
    if(ldc.obj2.xlass_def_id == 2){
      let crnt = parseInt(ldc.crnt);
      seg = ldc.segmap.get(crnt);
      data = {
          meta: {
              id: crnt + 1
          },
          value: {
              beg: seg.beg,
              end: seg.end
          }
      };
      const src = data.value;
      const e = seg.endi;
      if(cursortime > src.beg && cursortime < src.end){
        const span = { offset: round_to_3_places(cursortime + split_line_margin) };
        span.length = round_to_3_places(src.end - span.offset);
        src.end = round_to_3_places(cursortime - split_line_margin);
        const b = ldc.obj.last_iid + 1;
        add_nodes1(2);
        const src2 = { beg: seg.begi, end: b };
        add_message(data.meta.id, 'change', src2);
        add_message('SegmentList', 'add', null);
        add_message('new.Arc', 'change', { beg: (b+2), end: e });
        add_nodes2(seg.docid, [ [ b, src.end ], [ b+2, span.offset ] ]);
        seg.nodes.get('Arc').node_value.set(src2);
        submit_form();
        if(f) add_callback(f);
      }
    }
    else{
      data = window.$(`#node-${ldc.crnt} .Audio`).data();
      const src = data.value;
      if(cursortime > src.beg && cursortime < src.end){
          const span = { offset: cursortime + split_line_margin };
          span.length = round_to_3_places(src.end - span.offset);
          src.end = round_to_3_places(cursortime - split_line_margin);
          if(ldc.nodes) seg.nodes.get('Segment').node_value.set(src);
          add_message(data.meta.id, 'change', src);
          const f2 = () => {
            event.dispatch(null, 'split_segment');
            return add_audio_to_list(src.docid, null, null, span);
          };
          add_transcript_line_split(span, f2, f);
      }
    }
  }
}

function merge_with_following_segment(ids, map, f){
    if(ids.id && ids.next){
      const id = ids.id;
      const next_id = ids.next;
      if(ldc.nodes){
        const crnt = parseInt(map.get(id).split('-')[1]);
        let seg = ldc.segmap.get(crnt);
        const seg1 = seg;
        const data = {
          meta: {
            id: crnt + 1
          },
          value: {
            beg: seg.begi,
            end: seg.endi
          }
        };
        const crnt2 = parseInt(map.get(next_id).split('-')[1]);
        seg = ldc.segmap.get(crnt2);
        const next_data = {
          meta: {
            id: crnt2 + 1
          },
          value: {
            beg: seg.begi,
            end: seg.endi
          }
        };
        // w.delete_transcript_line_based_on_segment_id(next_id, false);
        const src = data.value;
        src.end = next_data.value.end;
        if(ldc.obj2.xlass_def_id == 2){
          seg1.nodes.get('Arc').node_value.set(src);
        }
        else{
          next_data.value.beg = seg.docid;
          next_data.value.beg = seg.beg;
          next_data.value.beg = seg.end;
          seg1.nodes.get('Segment').node_value.set(src);
        }
        add_message(data.meta.id, 'change', src);
        const v1 = ldc.segmap.get(crnt).text;
        const v2 = ldc.segmap.get(crnt2).text;
        if(v2 && v2.length > 0){
          let v = { value: `${v1} ${v2}` };
          if(ldc.obj2.xlass_def_id == 2){
            seg1.nodes.get('Text').node_value.set(v);
          }
          else{
            seg1.nodes.get('Transcription').node_value.set(v);
          }
          add_message(crnt+2, 'change', v);
        }
        delete_transcript_line_based_on_segment_id(map, next_id, false);
        segments.update( (x) => x );
      }
      else{
        let data = $(`#${map.get(id)} .Audio`).data();
        let next_data = $(`#${map.get(next_id)} .Audio`).data();
        delete_transcript_line_based_on_segment_id(map, next_id, false);
        const src = data.value;
        src.end = next_data.value.end;
        add_message(data.meta.id, 'change', src);
        data = $(`#${map.get(id)} .Transcription`).data();
        next_data = $(`#${map.get(next_id)} .Transcription`).data();
        const v1 = data.value.value;
        const v2 = next_data.value.value;
        if(v2 && v2.length > 0){
          add_message(data.meta.id, 'change', {
            value: `${v1} ${v2}`
          });
        }
        $(`#node-${data.meta.id}`).addClass('refresh');
      }
      submit_form();
      if(f) add_callback(f);
      event.dispatch(null, 'merged_segments');
    }
  }

function delete_transcript_line_based_on_listitem_id(id, submit, f) {
  let idd = `${parseInt(id) + 1}`;
  srcs.update( (srcs) => {
    for(const k in srcs){
      if(srcs[k][idd]) delete srcs[k][idd];
    }
    return srcs;
  } );
  add_message(id, 'delete', null);
  if(submit){
    submit_form();
    if(f) add_callback(f);
  }
}

function delete_transcript_line_based_on_segment_id(map, x, submit, f) {
  const sel = `#${map.get(x)}`;
  if(ldc.nodes){
    return delete_transcript_line_based_on_listitem_id(sel.split('-')[1], submit, f);
  }
  return delete_transcript_line_based_on_listitem_id($(sel).data().meta.id, submit, f);
}

function add_segment(segment, callback){
  let b = ldc.obj.last_iid + 1;
  let vals = [];
  if(ldc.obj2.xlass_def_id == 2){
  vals.push([ 'N', { docid: segment.docid, beg: segment.beg, type: 'real' } ]);
  add_message_listitem('NList', vals);
  vals = [];
  vals.push([ 'N', { docid: segment.docid, beg: segment.end, type: 'real' } ]);
  add_message_listitem('NList', vals);
  vals = [];
  vals.push([ 'Arc', { beg: b, end: (b+2) } ]);
  }
  else{
    vals.push([ 'Segment', { docid: segment.docid, beg: segment.beg, end: segment.end, type: 'real' } ]);
  }
  if(segment.text) vals.push([ 'Text', { value: segment.text } ]);
  if(segment.speaker) vals.push([ 'Speaker', { value: segment.speaker } ]);
  // console.log(segment);
  add_message_listitem('SegmentList', vals);
  add_callback(callback);
}

function redactf(iid, redact_text, redact_iid, redact_edit, f){
  if(ldc.nodes){
      const text = ldc.obj2.xlass_def_id == 2 ? 'Text' : 'Transcription';
      ldc.segmap.get(iid-2).nodes.get(text).node_value.set( { value: redact_text } );
      if(redact_edit) ldc.segmap.get(parseInt(redact_iid)-2).nodes.get(text).node_value.set( { value: redact_edit } );
  }
  add_message(iid.toString(), 'change', { value: redact_text });
  if(redact_edit) add_message(redact_iid, 'change', { value: redact_edit });
  submit_form();
  if(f) add_callback(f);
}

function delete_segments(ids, f){
  for(let id of ids) add_message(id, 'delete', null);
  submit_form();
  if(f) add_callback(f);
}

function add_section(section, id, f){
  let vals;
  if(ldc.obj2.xlass_def_id == 2){
    const seg = ldc.segmap.get(id);
    vals = [
      [ 'Arc', { beg: seg.begi, end: seg.endi } ],
      [ 'Name', { value: section } ]
    ];
  }
  else{
    vals = [
      [ 'Section', { value: section } ],
      [ 'BegSeg', { value: id.toString() } ]
    ];
  }
  add_message_listitem('SectionList', vals);
  // ldc_annotate.add_message(window.gdata('.SectionList').meta.id, 'add', null);
  // ldc_annotate.add_message('new.Section', 'change', { value: section });
  // ldc_annotate.add_message('new.BegSeg', 'change', { value: id });
  // ldc_annotate.submit_form();
  if(f) add_callback(f);
}

function close_section(h, f) {
  if(ldc.obj2.xlass_def_id == 2){
    extend_section(h, f);
    return;
  }
  if(window.get_constraint('section_order_forced') === true){
    section_order_forced_close(h);
  }
  else{
    close_section2(h, f);
  }
}
function section_order_forced_close(hh){
  const h = get_open_section(hh.iid);
  if(h && h.id) set_pointer(h.eseg.meta.id, h.id);
}

function extend_section(hh) {
  const h = get_last_section(hh.iid);
  console.log(h);
  if(!h.sec) return;
  const src = { beg: h.sec.begi, end: h.seg.endi };
  add_message(h.sec.iid+1, 'change', src);
  submit_form();
  if(f) add_callback(f);
}

function close_section2(hh) {
  const h = get_open_section(hh.iid);
  if(h){
    if(h.same){
      if(h.id){
        set_pointer(h.eseg.meta.id, h.id, f);
      }
    }
    else{
      h.overlap = false;
      h.src = {
        beg: h.a.value.beg,
        end: h.b.value.end
      };
      const last_section = find_last_section(h);
      if(h.overlap) alert("sections can't overlap");
      else if(h.id) set_pointer(h.eseg.meta.id, h.id, f);
    }
  }
}

function set_pointer(pointer, segment, f) {
  console.log('setting pointer ' + pointer)
  add_message(pointer, 'change', { value: segment.toString() });
  submit_form();
  if(f) add_callback(f);
}

function delete_nodes_after(after, f){
  let anyDeletion = false;
  document.querySelectorAll(".Node").forEach(n=>{
    const data = $(n).data("meta");
    if (data === undefined) return;
    const id = Number(data.id);
    if (isNaN(id) || id < 4 || id <= after) return;
    add_message(id, 'delete', null);
    anyDeletion = true;
  });
  if (anyDeletion){
    submit_form();
    if(f) add_callback(f);
  }
}

function add_nodes1(n){
  for(let i = 0; i < n; i++){
    add_message('NList', 'add', null);
  }
}

function add_nodes2(docid, times){
  for(const x of times){
    add_message(x[0]+1, 'change', { docid: docid, beg: x[1], type: 'real' });
  }
}

function add_audio_to_list(docid, list_selector, audio_path, span){
  if(false) console.log(span);
  if (span.length === 0) {
    // this doesn't always make sense
    return alert('select a region first');
  } else {
    const etime = span.end || (span.offset + span.length);
    const src = {
      docid: docid,
      beg: round_to_3_places(span.offset),
      end: round_to_3_places(etime),
      type: 'real'
    };
    let b;
    if(ldc.obj2.xlass_def_id == 2){
      b = ldc.obj.last_iid + 1;
      add_nodes1(2);
    }
    if(false){// (this.debug) {
      console.log('list');
      // console.log(list_selector);
    }
    add_message($('.SegmentList').data().meta.id, 'add', null);
    // w = if w.active_channel is 0 then waveform else waveform2
    // src.play_head = src.beg;
    if (false) { //@debug
      console.log('adding line');
      console.log(src);
    }
    if(ldc.obj2.xlass_def_id == 2){
      add_message('new.Arc', 'change', { beg: b, end: (b+2) });
      add_nodes2(docid, [ [ b, src.beg ], [ b+2, src.end ] ]);
    }
    else{
      add_message('new.Segment', 'change', src);
    }
    if (span.transcript) {
      const name = ldc.obj2.xlass_def_id == 2 ? 'new.Text' : 'new.Transcription';
      add_message(name, 'change', { value: span.transcript });
    }
    if (span.speaker) {
      add_message('new.Speaker', 'change', { value: span.speaker });
    } else {
      const speaker = ldc.vars.last_speaker_used;
      if(speaker) add_message('new.Speaker', 'change', { value: speaker });
    }
    return 'submit';
  }
}

function add_audio_to_listq(f){
  submit_form();
  if(f) add_callback(f);
}

function add_audio_to_listp(docid, span, f){
  const r = add_audio_to_list(docid, null, null, span);
  if(r === 'submit'){
    add_audio_to_listq(null);
    if(f) add_callback(f);
  }
}

function delete_section(id, f){
  if (id) {
    if (id === 'all') {
      $('.SectionListItem').each(function(i, x) {
        const iid = $(x).data().meta.id;
        add_message(iid, 'delete', null);
      });
    } else {
      add_message(id, 'delete', null);
    }
    submit_form();
    if(f) add_callback(f);
  }
};

function set_text(iid, value, transcription, f){
  const text = ldc.obj2.xlass_def_id == 2 ? 'Text' : 'Transcription';
  if(ldc.nodes) transcription.nodes.get(text).node_value.set( { value: value } );
  add_message(iid, 'change', { value: value });
  submit_form();
  add_callback(f);
}

function add_empty_segments(emptySegments){
  emptySegments.forEach( s => 
    add_message(s.value.id, 'change', {value: s.value.words.join(" ")})
  );
  if (emptySegments.length){
    submit_form();
    add_callback( () => ldc.main.refresh() );
  }
}

function update_node(docid, n, r, begend){
  const seg = ldc.segmap.get(parseInt(n.split('-')[1])).nodes.get('Arc');
  const v = { docid: docid, beg: r, type: 'real' };
  add_message(seg.value[begend]+1, 'change', v);
  submit_form();
}

function update_wave(wave_docid, n, span_offset, span_end, f){
  if(ldc.nodes){
    let seg = ldc.segmap.get(parseInt(n.split('-')[1])).nodes.get('Segment');
    n = seg.iid;
    let src = {
        docid: wave_docid,
        beg: span_offset,
        end: span_end,
        type: 'real'
    };
    add_message(n, 'change', src);
  }
  else{
    n = $(`#${n}`).data().Segment.meta.id;
    // ww = if w.active_channel is 0 then w else waveform2
    add_message(n, 'change', {
        docid: wave_docid,
        beg: span_offset,
        end: span_end,
        play_head: span_offset,
        timestamps: true
    });
  }
  submit_form();
  if(f) add_callback(f);
}

// function split_segment(data, seg, src, span, f){
//   if(ldc.nodes) seg.nodes.get('Segment').node_value.set(src);
//   add_message(data.meta.id, 'change', src);
//   add_transcript_line_split(span, f);
// }

function add_transcript_line_split(span, f2, f){ //add_transcript_line(aa, bb, 'split');
  const r = f2(span);
  if(r === 'submit'){
    submit_form();
    if(f) add_callback(f);
  }
}

function check_for_submit(r, f){
  if(r === 'submit'){
    submit_form();
    if(f) add_callback(f);
  }
}

function save_redaction(iid, redact_text, redact_iid, redact_edit, f){
  add_message(iid.toString(), 'change', { value: redact_text });
  if(redact_edit) add_message(redact_iid, 'change', { value: redact_edit });
  submit_form();
  if(f) add_callback(f);
}

function add_cb(f){ add_callback(f); }

export {
  set_ldc,
  done,
  broken,
  skip,
  change_value,
  change_value_src,
  delete_all,
  delete_all2,
  delete_all_sections,
  delete_last_section,
  create_test_segment,
  merge_with_following_segment,
  delete_transcript_line_based_on_segment_id,
  add_segment,
  add_section,
  redactf,
  delete_segments,
  close_section,
  delete_nodes_after,
  add_audio_to_list,
  add_audio_to_listp,
  add_audio_to_listq,
  delete_section,
  set_text,
  add_empty_segments,
  update_wave,
  update_node,
  // split_segment,
  check_for_submit,
  split_segment_at_cursor,
  save_redaction,
  add_cb
}