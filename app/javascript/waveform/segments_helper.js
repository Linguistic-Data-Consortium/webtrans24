import { Keyboard } from './keyboard'
import { segments, undefined_segments, sections } from './stores'
import { add_source_audio_collision } from './sources_stores'
let debug = false;
function update_segments(){
  if(window.ldc.node_lists) return;
    const o = segment_list_f('segments');
    segments.update( (x) => o.segments );
    undefined_segments.update( (x) => o.undefined_segments );
    sections.update( (x) => o.sections );
}

function update_segments2(json){
  const ns = window.ldc.ns;
  json.map( (x) => x.readonly = true );
  index_segments(json, ns);
  // let sections = Object.values(ns.index_sections_by_name);
  // ns.main.set_segments(json, sections, 'readonly');
  segments.update( (x) => json );
}

function segment_list_f(show){
  const ns = window.ldc.ns;
  // if(!($(".ChannelA").length > 0)) return;
  const pair = create_segments();
  const segments = pair[0];
  const undefined_segments = pair[1];
  index_segments(segments, ns);
  const sections = (function() {
    const ref = ns.index_sections_by_name;
    const results = [];
    for (let k in ref) {
      let v = ref[k];
      results.push(v);
    }
    return results;
  })();
  if(debug){
    console.log("INDEX");
    console.log(that.index_sections_by_name);
    console.log('TEST');
    console.log(segments);
    console.log(sections);
  }
  const o = {
    segments: segments,
    undefined_segments: undefined_segments,
    sections: sections,
    show: show
  };
  return o;
  // ns.main.set_segments(segments, sections, show);
}
 
function create_segments() {
  const vars = window.ldc.vars;
  const sel1 = `.${vars.add_from_waveform_list}Item`;
  const sel2 = `.${vars.add_from_waveform_audio}`;
  const sel3 = `.${vars.add_from_waveform_text}`;
  const sel4 = ".Speaker";
  const segments = [];
  const undefined_segments = [];
  $(sel1).each(function(i, x) {
    const data = $(x).find(sel2).data();
    const src = data.value;
    if(!src.beg && src.beg != 0){
      undefined_segments.push($(x).data().meta.id);
      return;
    }
    const c1 = {
      id: `unsorted-${i}`,
      iid: $(x).data().meta.id,
      docid: src.docid,
      beg: src.beg,
      end: src.end,
      text: $(x).find(sel3).data().value.value || '',
      speaker: $(x).find(sel4).data().value.value || '',
      section: null,
      error: null
    };
    let n1 = c1.text.match(/\(/g);
    if(!n1) n1 = [];
    let n2 = c1.text.match(/\)/g);
    if(!n2) n2 = [];
    if(c1.text && n1.length != n2.length) c1.error = "unbalanced parens";
    // if(c1.text && n1 && n2) c1.error = 'x'
    segments.push(c1);
  });
  segments.sort( (x, y) => x.beg - y.beg );
  return [ segments, undefined_segments ];
}
 
function index_segments(segments, ns){
  const that = ns;
  that.index = new Map();
  that.index2 = new Map();
  that.index3 = new Map();
  const w = that.waveform;
  w.set_playing_transcript_line_index = that.index;
  that.index_segments_by_id = new Map();
  // active = w.set_active_transcript_line null
  const segmc = window.ldc.c2;
  let active = segmc ? segmc.get_active() : null;
  let aactive = null;
  let aaactive = null;
  if (active && $(`#${active}`).length) {
    aactive = String($(`#${active}`).data().iid);
  }
  w.map = new Map();
  w.rmap = new Map();
  let i;
  let j;
  let ref;
  let c1;
  for (i = j = 0, ref = segments.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
    c1 = segments[i];
    c1.id = `segment-${i}`;
    that.index_segments_by_id.set(c1.id, c1);
    // that.index_segments_by_id[id] = c1
    let node_id = `node-${c1.iid}`;
    w.map.set(c1.id, node_id);
    w.rmap.set(node_id, c1.id);
    that.index.set(c1.beg, [c1.end, c1.id]);
    that.index2.set(String(i), c1);
    that.index3.set(c1.id, String(i));
    if (aactive === String(c1.iid)) {
      // active = id if active is w.map[id]
      aaactive = c1.id;
    }
    c1.section = null;
  }
  if ($('.SectionList').length === 1) {
    let sss = null;
    if(window.ldc.nodes) create_section_index2(ns);
    else                 create_section_index(ns);
    const all = Object.values(that.index_sections_by_name).sort( (a, b) => a.begr - b.begr );
    for(let i = 0; i < all.length; i++){
      let ss = all[i];
      if(!ss.endr){
        if(i < all.length - 1) ss.endr = all[i+1].begr;
        else                   ss.endr = 9999999;
      }
    }
    let l;
    let ref1;
    for (i = l = 0, ref1 = segments.length; (0 <= ref1 ? l < ref1 : l > ref1); i = 0 <= ref1 ? ++l : --l) {
      c1 = segments[i];
      // let ss = that.index_sections_by_segment_id[c1.id];
      // if (ss) {
      //   sss = ss;
      // }
      // c1.section = sss;
      // if (ss && ss.end === c1.id) {
      //   sss = null;
      // }
      for(let ss of all){
        if(c1.beg >= ss.begr && c1.end <= ss.endr){
          c1.section = ss;
        }
      }
    }
  }
  add_source_audio_collision(that.waveform.docid);
  w.update_underlines = true;
  window.ldc.c1.set_active_transcript_line_helper(aaactive);
  window.ldc.c2.set_active_transcript_line(aaactive, true);
  if(debug){
    console.log('HERE');
    console.log(aactive);
    console.log(that.index2);
  }
  active = aactive;
}

function create_section_index(ns){
  const that = ns;
  const w = ns.waveform;
  const begmap = {};
  const endmap = {};
  ns.index_sections_by_segment_id = {};
  ns.index_sections_by_name = {};
  return $('.SectionListItem').each(function(i, x) {
    var a, b, id, s, section;
    section = $(x).find(".Section").data().value.value;
    a = $(x).find('.BegSeg').data().value.value;
    b = $(x).find('.EndSeg').data().value.value;
    if (a && b && a === b) {
      id = w.rmap.get(`node-${a}`);
      s = {
        name: section,
        beg: id,
        end: id,
        list_item_id: $(x).data().meta.id
      };
      if(that.index_segments_by_id.has(id)){
        s.begr = that.index_segments_by_id.get(id).beg;
        s.endr = that.index_segments_by_id.get(id).end;
      }
      else{
        if(debug) console.log(`was segment ${id} deleted?`);
      }
      that.index_sections_by_segment_id[id] = s;
      return that.index_sections_by_name[section] = s;
    } else {
      if (a) {
        id = w.rmap.get(`node-${a}`);
        s = {
          name: section,
          beg: id,
          list_item_id: $(x).data().meta.id
        };
        if(that.index_segments_by_id.has(id)){
          s.begr = that.index_segments_by_id.get(id).beg;
        }
        else{
          if(debug) console.log(`was segment ${id} deleted?`);
        }
        that.index_sections_by_segment_id[id] = s;
        that.index_sections_by_name[section] = s;
      }
      if (b) {
        id = w.rmap.get(`node-${b}`);
        s = that.index_sections_by_name[section];
        s.end = id;
        if(that.index_segments_by_id.has(id)){
          s.endr = that.index_segments_by_id.get(id).end;
        }
        else{
          if(debug) console.log(`was segment (${b}, ${id}) deleted?`);
        }
        return that.index_sections_by_segment_id[id] = s;
      }
      if(!a && !b && !section){
        s = {
          name: section,
          list_item_id: $(x).data().meta.id
        };
        that.index_sections_by_name[section] = s;
      }
    }
  });
}

function create_section_index2(ns){
  const that = ns;
  const w = ns.waveform;
  const begmap = {};
  const endmap = {};
  ns.index_sections_by_segment_id = {};
  ns.index_sections_by_name = {};
  for(const [k, v] of secmap){
    let s;
    const x = window.ldc.nodes.get(k);
    const section = x.nodes.get("Name").value.value;
    const arc = x.nodes.get('Arc').value;
    const a = arc.beg;
    const b = arc.end;
    if (a && b && a === b) {
      // id = w.rmap.get(`node-${a}`);
      // s = {
      //   name: section,
      //   beg: id,
      //   end: id,
      //   list_item_id: x.iid
      // };
      // if(that.index_segments_by_id.has(id)){
      //   s.begr = that.index_segments_by_id.get(id).beg;
      //   s.endr = that.index_segments_by_id.get(id).end;
      // }
      // else{
      //   console.log(`was segment ${id} deleted?`);
      // }
      // that.index_sections_by_segment_id[id] = s;
      // that.index_sections_by_name[section] = s;
    } else {
      if (a) {
        // id = w.rmap.get(`node-${a}`);
        s = {
          name: section,
          // beg: id,
          begr: nmap.get(a).beg,
          list_item_id: x.iid
        };
        that.index_sections_by_name[section] = s;
      }
      if (b) {
        // id = w.rmap.get(`node-${b}`);
        s = that.index_sections_by_name[section];
        // s.end = id;
        s.endr = nmap.get(b).beg;
      }
      if(!a && !b && !section){
        s = {
          name: section,
          list_item_id: x.iid
        };
        that.index_sections_by_name[section] = s;
      }
    }
  }
}

function get_new_speaker(id, hh){
  const kb = new Keyboard('speaker');
  const h = {
    keyboard: kb,
    setf: (value) => set_speaker_value(id, value, hh.rf, hh.nodes),
    title: 'type speaker, hit enter'
  };
  hh.input_screen.open_helper(h);
}

function last_section_obj(id, current_section){
  let length;
  if(window.ldc.nodes) length = window.ldc.secmap.size;
  else                 length = document.getElementsByClassName('SectionListItem').length;
  const h = {
    id: id,
    current_section: current_section,
    length: length,
    exists: false,
    repeat: false,
    overlap: false
  };
  if(length > 0){
    const nodeb = window.gdata(`#node-${id} .Segment`);
    if(current_section === null){
      h.src = null;
    }
    else{
      h.src = {
        beg: nodeb.value.beg,
        end: nodeb.value.end
      };
    }
    const last_section = find_last_section(h);
    if($(last_section).find('.EndSeg.empty').length === 1){
      alert('last section is still open');
      return;
    }
    const seg = $(last_section).find('.EndSeg').data().value.value;
    const nodea = window.gdata(`#node-${seg} .Segment`);
    if(nodea) h.a = nodea.value.end;
    if(nodeb) h.b = nodeb.value.beg;
  }
  return h;
}

function overlap(a, b){
  return a.beg <= b.end && a.end >= b.beg;
}

function get_last_section(id){
  const h = { id: id };
  if(debug) console.log('SSSSSS')
  const seg = segmap.get(id);
  // const segend = segmap.get(id).end;
  // h.end = segend;
  // h.map = secmap;
  h.seg = seg;
  let found = null;
  for(const [k, v] of secmap){
    if(v.beg <= seg.end){
      if(v.end >= seg.beg){
        // alert('segment overlaps section');
        h.sec = v;
        return h;
      }
      if(found){
        if(v.end > found.end) found = v; // v is closer
      }
      else{
        found = v;
      }
    }
  }
  if(!found) alert('no previous section');
  else       h.sec = found;
  return h;
}

function get_open_section(id){
  const h = { id: id };
  let length;
  if(window.ldc.nodes) length = secmap.size;
  else                 length = document.getElementsByClassName('SectionListItem').length;
  let last_section = null;
  let segs;
  if(window.ldc.nodes) segs = [...secmap].map( ([k,v]) => v).filter(x => x.nodes.get('EndSeg').node_value_id == 0);
  else                 segs = document.getElementsByClassName('EndSeg empty');
  if (segs.length === 0) {
    alert('no open sections');
    return;
  }
  let iid;
  let seg;
  if(window.ldc.nodes){
    if(debug){
      console.log('SSSSSS')
      console.log(segs)
    }
    iid = segs[0].iid;
    const sss = window.ldc.nodes.get(iid);
    h.eseg = sss.nodes.get('EndSeg');
    h.eseg.meta = { id: h.eseg.iid };
    h.current_section = sss.nodes.get('Section').value.value;
    h.bseg = sss.nodes.get('BegSeg');
    h.bseg.meta = { id: h.bseg.iid };
    seg = parseInt(h.bseg.value.value);
    if(seg !== id){
      h.a = window.ldc.nodes.get(seg).nodes.get('Segment');
      h.a.value.beg = h.a.value.beg;
      h.b = window.ldc.nodes.get(id).nodes.get('Segment');
      // alert "#{a} #{b}"
      if(h.a.value.end > h.b.value.beg){
        h.id = null;
        alert(`closing segment must follow opening segment, but ${h.a.value.end} > ${h.b.value.beg}`);
        return;
      }
    }
    else{
      h.same = true;
    }
  }
  else{
    iid = segs[0].parentNode.id.split('-')[1];
    h.eseg = window.gdata(`#node-${iid} .EndSeg`)
    h.current_section = window.gdata(`#node-${iid} .Section`).value.value;
    h.bseg = window.gdata(`#node-${iid} .BegSeg`);
    seg = h.bseg.value.value;
    if(seg !== id){
      h.a = window.gdata(`#node-${seg} .Segment`);
      h.a.value.beg = h.a.value.beg;
      h.b = window.gdata(`#node-${id} .Segment`);
      // alert "#{a} #{b}"
      if(h.a.value.end > h.b.value.beg){
        h.id = null;
        alert(`closing segment must follow opening segment, but ${h.a.value.end} > ${h.b.value.beg}`);
        return;
      }
    }
    else{
      h.same = true;
    }
  }
  return h;
}

function find_last_section(h) {
  const src = h.src;
  let last = null;
  let last_section = null;
  $('.SectionListItem').each(function(i, x) {
    let iid = $(x).data().meta.id;
    if(Number(iid) > Number(last)){
      last = iid;
      last_section = x;
    }
    if($(x).find('.Section').data().value.value === h.current_section){
      h.exists = true;
    }
    else{
      if(src && src.beg && src.end) {
        let begseg = get_begendseg(x, '.BegSeg', h);
        let endseg = get_begendseg(x, '.EndSeg', h);
        if(begseg && endseg){
          if(begseg <= src.end && endseg >= src.beg || h.repeat) h.overlap = true;
        }
      }
    }
  });
  return last_section;
}

function get_begendseg(x, sel, h){
  let begseg = $(x).find(sel).data();
  if(begseg){
    begseg = begseg.value.value;
    if(begseg){
      if(begseg === h.id){
        h.repeat = true;
      }
      else{
        begseg = $(`#node-${begseg} .Segment`).data();
        if(begseg){
          // alert JSON.stringify begseg.value
          if(sel === '.BegSeg') begseg = begseg.value.beg;
          else                  begseg = begseg.value.end;
        }
      }
    }
  }
  return begseg;
}

const segmap = new Map();
const secmap = new Map();
const nmap = new Map();
const gmap = new Map();
if(!window.ldc) window.ldc = {};
window.ldc.segmap = segmap;
window.ldc.secmap = secmap;
window.ldc.nmap = nmap;
function sources_object_add_node_helper(id, x){
  const data = {
    meta: {
      id: id
    },
    value: {
      docid: x.docid,
      beg: x.beg,
      end: x.end
    }
  };
  sources_object_add_node(null, data);
}
function new_update_segments(){
  if(!window.ldc.node_lists) return;
  if(window.ldc.obj2.xlass_def_id == 2){
  window.ldc.node_lists.get('NList').subscribe((x) => {
    let del = false;
    for(const [k, v] of nmap){
      if(!x.has(k)){
        del = true
        v.Node();
        nmap.delete(k);
      }
    }
    let i = -1;
    for(const [k, v] of x){
      i++;
      if(nmap.has(k)){
        // let c2 = segmap.get(k);
        // c2.id = `unsorted-${i}`;
        // tsegs.push(c2);
      }
      else{
        // console.log(k)
        // let s = v.nodes.get('Segment');
        // console.log(s);
        // const data = $(x).find(sel2).data();
        // const src = data.value;
        const c1 = {
        }

        nmap.set(k, c1);

        c1.Node = v.nodes.get('N').node_value.subscribe( (x) => {
          c1.docid = x.docid;
          c1.beg = x.beg;
          for(const [kk, v] of segmap){
            if(v.begi == k){
              v.docid = x.docid;
              v.beg = x.beg;
              sources_object_add_node_helper(`${kk+1}`, v);
            }
            if(v.endi == k){
              v.docid = x.docid;
              v.end = x.beg;
              sources_object_add_node_helper(`${kk+1}`, v);
            }
          }
          for(const [kk, v] of secmap){
            if(v.begi == k) v.beg = x.beg;
            if(v.endi == k) v.end = x.beg;
          }
          sort_segments();
          sort_sections();
        } );
      }
    }
  });
  }
  window.ldc.node_lists.get('SectionList').subscribe((x) => {
    let del = false;
    for(const [k, v] of secmap){
      if(!x.has(k)){
        del = true
        v.Arc();
        v.Name();
        secmap.delete(k);
        sort_segments();
        sort_sections();
    }
    }
    // if(del) sort_segments();
    let i = -1;
    for(const [k, v] of x){
      i++;
      if(secmap.has(k)){
      }
      else{
        const c1 = {
            id: `unsorted-${i}`,
            iid: k,
            nodes: v.nodes
        }

        secmap.set(k, c1);
        c1.Arc = v.nodes.get('Arc').node_value.subscribe( (x) => {
          if(x.beg){
            if(debug){
              console.log(x)
              console.log(nmap)
            }
            c1.begi = x.beg;
            c1.endi = x.end;
            c1.docid = nmap.get(x.beg).docid;
            c1.beg = nmap.get(x.beg).beg;
            c1.end = nmap.get(x.end).beg;
            if(debug){
              console.log('sort')
              console.log(c1)
              console.log(c1.beg)
              console.log(x)
              console.log(x.begi)
            }
            sort_segments();
            sort_sections();
          }
        } );
        // let y = v.nodes.get('Section');
        // y.node_value.subscribe( (x) => {
        c1.Name = v.nodes.get('Name').node_value.subscribe( (x) => {
          c1.section = x.value;
          window.ldc.sections.set(x.value, x.value);
          sort_segments();
          sort_sections();
        } );
      }
    }
  });
  window.ldc.node_lists.get('SegmentList').subscribe((x) => {
    let del = false;
    for(const [k, v] of segmap){
      if(!x.has(k)){
        del = true
        if(window.ldc.obj2.xlass_def_id == 2){
          v.Arc();
          v.Text();
        }
        else{
          v.Segment();
          v.Transcription();
        }
        v.Speaker();
        segmap.delete(k);
      }
    }
    if(del) sort_segments();
    // const tsegs = [];
    // const tundef = [];
    let i = -1;
    for(const [k, v] of x){
      i++;
      if(segmap.has(k)){
        // let c2 = segmap.get(k);
        // c2.id = `unsorted-${i}`;
        // tsegs.push(c2);
      }
      else{
        // console.log(k)
        // let s = v.nodes.get('Segment');
        // console.log(s);
        // const data = $(x).find(sel2).data();
        // const src = data.value;
        const c1 = {
            id: `unsorted-${i}`,
            iid: k,
            // docid: '',
            // beg: 0.001,
            // end: 0.001,
            text: '', // $(x).find(sel3).data().value.value || '',
            speaker: '', //$(x).find(sel4).data().value.value || '',
            section: null,
            error: null,
            nodes: v.nodes
        }

        segmap.set(k, c1);
        if(window.ldc.obj2.xlass_def_id == 2){
        c1.Arc = v.nodes.get('Arc').node_value.subscribe( (x) => {
          if(x.beg){
            if(debug){
              console.log(x)
              console.log(nmap)
            }
            c1.begi = x.beg;
            c1.endi = x.end;
            c1.docid = nmap.get(x.beg).docid;
            c1.beg = nmap.get(x.beg).beg;
            c1.end = nmap.get(x.end).beg;
            if(debug){
              console.log('sort')
              console.log(c1)
              console.log(c1.beg)
              console.log(x)
              console.log(x.begi)
            }
            sources_object_add_node_helper(`${k+1}`, c1);
            sort_segments();
            sort_sections();
          }
        } );
        c1.Text = v.nodes.get('Text').node_value.subscribe( (x) => {
          c1.text = x.value;
          sort_segments();
        } );
        }
        else{
          c1.Segment = v.nodes.get('Segment').node_value.subscribe( (x) => {
            c1.docid = x.docid;
            c1.beg = x.beg;
            c1.end = x.end;
            if(debug){
              console.log('sort')
              console.log(c1)
              console.log(c1.beg)
              console.log(x)
              console.log(x.begr)
            }
            sources_object_add_node_helper(`${k+1}`, x);
            sort_segments();
            sort_sections();
          } );
          c1.Transcription = v.nodes.get('Transcription').node_value.subscribe( (x) => {
            c1.text = x.value;
          } );
        }
        c1.Speaker = v.nodes.get('Speaker').node_value.subscribe( (x) => {
          c1.speaker = x.value;
          window.ldc.speakers.set(x.value, x.value);
          segments.update( (x) => x );
        } );
        // let n1 = c1.text.match(/\(/g);
        // if(!n1) n1 = [];
        // let n2 = c1.text.match(/\)/g);
        // if(!n2) n2 = [];
        // if(c1.text && n1.length != n2.length) c1.error = "unbalanced parens";
        // // if(c1.text && n1 && n2) c1.error = 'x'

        // if(!c1.beg && c1.beg != 0){
        //   tundef.push(k);
        // }
        // else{
        //   segmap.set(k, c1);
        //   tsegs.push(c1);
        // }
      }
    }
    // tsegs.sort( (x, y) => x.beg - y.beg );
    // index_segments(tsegs, window.ldc.ns);
    // segments.update( (x) => tsegs );
    // undefined_segments.update( (x) => tundef );
  });
}

function sort_segments(){
  const tsegs = [];
  const tundef = [];
  for(const [k, v] of segmap){
    if(!v.beg && v.beg != 0){
      tundef.push(k);
    }
    else{
      tsegs.push(v);
    }
  }
  tsegs.sort( (x, y) => x.beg - y.beg );
  index_segments(tsegs, window.ldc.ns);
  segments.set(tsegs);
  undefined_segments.set(tundef);
}

function sort_sections(){
  const ref = window.ldc.ns.index_sections_by_name;
  const results = [];
  for (let k in ref) {
    let v = ref[k];
    results.push(v);
  }
  sections.set(results);
}

export {
  new_update_segments,
  update_segments,
  update_segments2,
  get_new_speaker,
  last_section_obj,
  find_last_section,
  get_open_section,
  get_last_section
}
