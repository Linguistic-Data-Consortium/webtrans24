import { postp } from '../getp';
let messages = []; // message(s) to send to the annotate controller
const submissions = {}; // messages sent
let annotations_promise = Promise.resolve();
//this function adds a message to the queue for annotation
function add_message(n, m, v){
    if(m == 'add'){
        // console.log('aaaaaaaaaaaaa')
        // console.log(n)
        // console.log(nodes[n])
        // console.log(ldc_nodes.get_node_class(nodes[n].meta.node_class_id))
        if(window.ldc && window.ldc.addf){
            v = window.ldc.addf(n);
            n = '0';
        }
        else{
            v = window.nodes[n].meta.node_class_id;
        }
    }
    if(m == 'change' && window.ldc && window.ldc.changef) n = window.ldc.changef(n, v);
    if(m == 'delete' && window.ldc && window.ldc.deletef) window.ldc.deletef(n);
    if(n == '0' && window.ldc) n = 0;
    messages.push( { node: n, message: m, value: v } );
}
function add_message_listitem(list, child_values_to_add){
    add_message_listitem_by_id($(`.${list}`).data().meta.id, child_values_to_add);
}
function add_message_listitem_by_id(id, child_values_to_add, callback, nosubmit = false) {
    add_message(id, 'add', null);
    $.each(child_values_to_add, function(i, x) {
      // x[0] is node name, x[1] is value
      add_message(`new.${x[0]}`, 'change', x[1]);
    });
    if (!nosubmit) {
      submit_form();
    }
    if (callback) {
      add_callback(callback);
    }
}

function submit_form(){
    var m = [];
    m = messages.slice();
    messages = [];
    annotations_promise = annotations_promise.then( function(){
        return submit_form_old(m);
    });
}

function add_callback(f){
    annotations_promise = annotations_promise.then(f);
}

let d;

//this is the function which actually submits annotations to the annotate action in the annotate controller
function submit_form_old(m){
    var messages = m;
    var promise = Promise.resolve();
    console.log( 'SUBMIT' )
    var obj = {};
    obj.messages = messages;
    d = new Date();
    obj.client_time = d.getTime();
    obj.kit_uid = $('.Root').data().obj._id
    obj.xlass_def_id = $('.Root').data().obj.xlass_def_id
    if(messages.length > 0){
        if($('.Root').data().obj.read_only){
            var mmessage = 'read only, json request would have been: ' + JSON.stringify(obj);
            alert(mmessage);
        }
        else{
            var url = '/annotations';
            submissions[obj.client_time] = obj
            pending_save_before(messages);
            promise = postp(url, { task_user_id: $('.Root').data().obj.task_user_id, json: JSON.stringify(obj) }).then(function(data){ console.time('annotate2'); annotate2(data, obj.client_time); console.timeEnd('annotate2'); });
            obj.received = false;
            submissions[obj.client_time] = obj;
        }
        messages = [];
    }
    return promise;
}

const avm = {
    messages: [],
    counter: -1
  };
  window.avm = avm;
  function save_message(m) {
    avm.messages.push({
      sent: m,
      received: null
    });
  }
  function confirm_message(m) {
    var i, pair, problem, sent, that;
    that = this;
    avm.counter += 1;
    i = avm.counter;
    console.log('confirming');
    if(m.beg) m.type = 'real';
    pair = avm.messages[i];
    if (pair) {
      if (pair.received) {
        return console.error('avm error 2');
      } else if (m.message !== pair.sent.message) {
        console.log(m);
        console.log(pair);
        console.error('avm error 3');
        if (m.error) {
          return alert(m.error);
        }
      } else {
        pair.received = m;
        sent = pair.sent;
        switch (m.message) {
          case 'change':
            if (m.old_id !== parseInt(sent.node)) {
              console.log(pair);
              return console.error('avm error 5');
            } else if (!node_value_compare(m.node.value, sent.value)) {
              console.log(pair);
              return console.error('avm error 6');
            } else {
              return console.log(`message ${i} ok`);
            }
            break;
          case 'add':
            if (m.old_id !== parseInt(sent.node)) {
              console.log(pair);
              return console.error('avm error 7');
            } else {
              problem = false;
              $.each(m.nodes, function(i, x) {
                var id, name;
                if (i === 0) {
                  id = x.iid;
                  name = x.name;
                } else {
                  id = x.meta.id;
                  name = x.meta.name;
                }
                if(window.ldc.obj){
                  for(let y of window.ldc.obj.nodes){
                    if(y.iid == id){
                      if (y.name !== name) {
                        console.log('problem')
                        console.log(x);
                        return problem = true;
                      }
                    }
                  }
                }
                else{
                  if ($(`#node-${id}`).data().meta.name !== name) {
                    return problem = true;
                  }
                }
              });
              if (problem) {
                console.log(pair);
                console.error('avm error 8');
                return that.error_in_message();
              } else {
                console.log(pair);
                return console.log(`message ${i} ok`);
              }
            }
            break;
          case 'delete':
            return console.log('delete');
          case 'done':
            return console.log('done');
          default:
            return console.error('avm error 4');
        }
      }
    } else {
      return console.error("avm error 1");
    }
  }
  function node_value_compare(x, y) {
    var b, k, v, yy;
    if (typeof x === 'undefined') {
      // console.log 'xxxx'
      // console.log typeof(x)
      // console.log x
      // console.log y
      return false;
    }
    if (x.value === "" && y.value === "") {
      // console.log 'xxx'
      // console.log x
      // console.log y
      return true;
    }
    if (x.value === "") {
      // console.log JSON.stringify({value: null})
      // console.log JSON.stringify(y)
      return JSON.stringify({
        value: null
      }) === JSON.stringify(y);
    } else {
      // alert(JSON.stringify(x))
      // alert(JSON.stringify(y));
      // alert(JSON.stringify(x) is JSON.stringify(y));
      // console.log 'xx'
      // console.log x
      // console.log y
      // console.log JSON.stringify(x)
      // console.log JSON.stringify(y)
      yy = {};
      for (k in y) {
        v = y[k];
        if (k !== 'level' && k !== 'node' && k !== 'timestamps') {
          yy[k] = v;
        }
      }
      if(x['type']) yy['type'] = x['type'];
      return JSON.stringify(x) === JSON.stringify(yy);
    }
    b = true;
    $.each(['value'], function(i, k) {
      if (x[k] !== y[k]) {
        return b = false;
      }
    });
    return b;
  }

function pending_save_before(messages){
    console.log('pending_save_before');
    console.log(messages);
    let selector;
    $.each(messages, function(i, m){
        // console.log(i);
        // console.log(m);
        if(!window.ldc.nodes){
        if(m.message == 'change'){
            selector = '#node-' + m.node;
            window.pending_save_change(m);
        }
        if(m.message == 'add'){
            window.pending_save_add(m);
        }
        if(m.message == 'delete'){
            window.pending_save_delete(m);
        }
        }
        save_message(m);
    });
    if(window.ldc.nodes) return;
    window.after_annotate(messages, null, null);
}

function annotate2(messages, client_time){
    console.log(client_time);
    submissions[client_time].received = true;
    if(messages.error){
        alert('error');
        console.error(messages.error)
        if(messages.full_error) console.log(messages.full_error);
        return;
    }
    console.log("ANN2")
    console.log(messages)
    $.each(messages, function(i, hash){
        console.log('getting message');
        console.log(hash);
        confirm_message(hash);
        if(hash.hasOwnProperty('noop')){
            return;
        }
        if(hash.hasOwnProperty('error')){
            if(hash.error === 'This tree is locked.'){
                $('#tree_locked_modal').addClass('open');
                $("body").addClass("modal-open");
                if(hash.current){
                    $('#current_locked').show()
                }
                else{
                    $('#current_locked').hide()
                }
            }
            else{
                $('#message_dialog').html(hash.error).dialog('option', 'title', 'Error').dialog('open');
            }
            return;
        }
        if(hash.hasOwnProperty('redirect')){
            if(hash.message === 'inactive'){
                $('.ann_pane').html('<h1>This tasks is inactive, redirecting.</h1>')
                setTimeout( function(){
                    window.location.href = hash.redirect;
                }, 3000);
                return;
            }
            else{
                $('.ann_pane').html('');
                window.location.href = hash.redirect;
                return;
            }
        }
        if(window.ldc && window.ldc.obj){
            $('#node-0-dummy').remove();
            return;
        }
    });
}


export { add_message, add_message_listitem, submit_form, add_callback }
