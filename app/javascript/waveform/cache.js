import { fill_waveform_display_points } from './channel/buffer'
const cache = {};
const scache = {};
function fill_cache(k, buffer, width, w, wave_canvas_height, skip, samples_per_pixel_threshold){
    let b = w.samples_per_pixel > samples_per_pixel_threshold;
    let i = k.match(/[:_]B/) ? 1 : 0;
    let x = fill_waveform_display_points(buffer, w, wave_canvas_height, i, !b, skip, width);
    cache[k] = x[0];
    scache[k] = x[1];
}
function get_cache(k){
    return cache[k];
}
function get_scache(k){
    return scache[k];
}
export { fill_cache, get_cache, get_scache }