<script>
    import { onMount } from 'svelte';
    import Waveform from './waveform.svelte';
    import { getp } from '../getp';
    import { btn } from '../work/buttons';
    import { active_docid } from './stores';
    let { ldc } = $props();
    const permissions = ldc.permissions;
    const constraint_export_transcript = ldc.get_constraint('export_transcript');
    const constraint_export_transcript_to_task_admin = ldc.get_constraint('export_transcript_to_task_admin');
    const constraint_import_transcript = ldc.get_constraint('import_transcript');
    const constraint_import_transcript_auto = ldc.get_constraint('import_transcript_auto');
    const constraint_rtl = ldc.get_constraint('rtl');
    const constraint_speakers = ldc.get_constraint('speakers');
    const constraint_sections = ldc.get_constraint('sections');
    const constraint_section_order_forced = ldc.get_constraint('section_order_forced');
    const constraint_add_asr_segments = ldc.get_constraint('add_asr_segments');
    const constraint_asr_korean = ldc.get_constraint('asr_korean');
    let source_uid = $state();
    const waveform = {
        wave_audio: {},
        play_head: 0,
        playheads: new Map()
    };
    ldc.waveforms = [ waveform ];
    // ns.waveform = waveform;
    const redact = ldc.obj2.task_meta.redact;
    const xlass_def_id = ldc.obj2.xlass_def_id;
    let w = $state();
    setInterval(() => ldc.wc = w, 1000);
    // onMount( () => ldc.wc = w );
    export function update_segments(){
        setTimeout( () => {
            if(w) w.update_segments_with();
            else  update_segments();
        }, 500 );
    }
    // export function set_mode(x){ w.set_mode(x) }
    // export function get_mode(x){ return w.get_mode() }
    // export function set_times_then_draw(x, y){ if(w) w.set_times_then_draw(x, y) }
    // export function move_cursor(x, factor) { w.move_cursor(x, factor) }
    // export function move_cursor_lstep1(){ w.move_cursor_lstep1(); }
    // export function move_cursor_lstep2(){ w.move_cursor_lstep2(); }
    // export function move_cursor_lstep3(){ w.move_cursor_lstep3(); }
    // export function move_cursor_lstep4(){ w.move_cursor_lstep4(); }
    // export function move_cursor_rstep1(){ w.move_cursor_rstep1(); }
    // export function move_cursor_rstep2(){ w.move_cursor_rstep2(); }
    // export function move_cursor_rstep3(){ w.move_cursor_rstep3(); }
    // export function move_cursor_rstep4(){ w.move_cursor_rstep4(); }
    // export function move_selection_lstep1(){ w.move_selection_lstep1(); }
    // export function move_selection_lstep2(){ w.move_selection_lstep2(); }
    // export function move_selection_lstep3(){ w.move_selection_lstep3(); }
    // export function move_selection_lstep4(){ w.move_selection_lstep4(); }
    // export function move_selection_rstep1(){ w.move_selection_rstep1(); }
    // export function move_selection_rstep2(){ w.move_selection_rstep2(); }
    // export function move_selection_rstep3(){ w.move_selection_rstep3(); }
    // export function move_selection_rstep4(){ w.move_selection_rstep4(); }
    // export function move_window_lstep1(){ w.move_window_lstep1(); }
    // export function move_window_lstep2(){ w.move_window_lstep2(); }
    // export function move_window_lstep3(){ w.move_window_lstep3(); }
    // export function move_window_lstep4(){ w.move_window_lstep4(); }
    // export function move_window_rstep1(){ w.move_window_rstep1(); }
    // export function move_window_rstep2(){ w.move_window_rstep2(); }
    // export function move_window_rstep3(){ w.move_window_rstep3(); }
    // export function move_window_rstep4(){ w.move_window_rstep4(); }
    // export function set_current_selection(x, factor) { w.set_current_selection(x, factor) }
    // export function show_src(src, beg) { w.show_src(src, beg) }
    // export function toggle_zoom() { w.toggle_zoom() }
    // export function zoom_in() { w.zoom_in() }
    // export function zoom_out() { w.zoom_out() }
    // export function update(){                  w.update() }

    // export function show_help_screen_main(x){  w.show_help_screen_main(x) }
    // export function upload_transcript(){       w.upload_transcript() }

    // export function play_current_span_or_play_stop(){ w.play_current_span_or_play_stop(); }
    // export function play_current_span(){ w.play_current_span(); }

    // export function play_from_cursor(){ w.play_from_cursor(); }
    // export function play_from_selection_beg(){ w.play_from_selection_beg(); }
    // export function play_from_selection_end(){ w.play_from_selection_end(); }
    // export function cursor_time(){ return w.cursor_time() }
    // export function split_segment_at_cursor() { return w.split_segment_at_cursor() }
    // export function find_active_id(){ return t.find_active_id() }


    // let u;
    // export function undo(){ u.undo() }
    // export function refresh() { t.refresh() }
    function wait(data){
        if(data.first == true){
            first = true;
            let e = document.getElementById('main');
            e.innerHTML = '<h3>creating transcript...</h3>'
        }
        if(data.wait){
            let e = document.getElementById('main');
            e.innerHTML += '<div>working...</div>';
            console.log("waiting");
            setTimeout( () => check(true), 1000);
        }
        else{
            console.log(data);
            if(first) setTimeout( () => window.location.reload(), 2000);
        }
    }
    let first = false;
    function check(b){
        getp(`/preann?kit_id=${kit_id}&check=${b}`).then( (data) => wait(data) );
    }
    // check(false);
    export function use_transcript(t, x){
    }
    function userf(e){
        let f = e.detail.userf
        if(f == 'delete_all_confirmx'){
            // dispatch('userf', o);
        }
        else{
            if(w[f]) w[f](e.detail.e);
            else  console.log(`no function ${f}`)
        }
    }

    function one(){
        active_docid.update( () => 's3://coghealth/two/sw02001_m1.wav' )
    }
    function two(){
        // active_docid.update( () => 's3://coghealth/two/sw02001_m1.wav' )
        active_docid.update( () => 's3://coghealth/demo/CarrieFisher10s.wav' )
    }
    active_docid.subscribe( (x) => {
        source_uid = x && x.match(/\.(wav)$/) ? x : null;
    });
</script>

{#if false}
<div class="flex">
<button class="{btn} w-full" onclick={one}>one</button>
<button class="{btn} w-full" onclick={two}>two</button>
</div>
{/if}

<!-- <Undo bind:this={u} /> -->
{#key source_uid}
    {#if source_uid}
        <Waveform
            bind:this={w}
            on:userf={userf}
            {ldc}
            {source_uid}
            {redact}
            {permissions}
            {constraint_export_transcript}
            {constraint_export_transcript_to_task_admin}
            {constraint_import_transcript}
            {constraint_import_transcript_auto}
            {constraint_rtl}
            {constraint_speakers}
            {constraint_sections}
            {constraint_section_order_forced}
            {constraint_add_asr_segments}
            {constraint_asr_korean}
            {xlass_def_id}
        />
    {/if}
{/key}
