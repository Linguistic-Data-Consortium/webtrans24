function draw_ticks(t){
  const w = window.ldc.ns.waveform;
  let step = Math.floor(w.wave_scale*8000) / 200; // part of this operation is scaling, and part is arbitrary step frequency
  step = t.wave_display_length / 40;
  w.step1 = w.wave_scale;
  w.step2 = step;
  w.step3 = w.step2 * 2;
  w.step4 = w.step3 * 3;
  w.step2 = step * 2 / 5;
  const a = [];
  const ww = t.wave_display_length / t.wave_canvas_width;
  for(let i = 1; i < 40; i++){
    let ii = w.round_to_6_places(i*step);
    let x = ii / ww;
    if(x >= 0 && x <= t.wave_canvas_width){
      let o = { x: x, y_start: 0, y_end: 10 };
      if(i % 2 == 0){
        o.time_x = x;
        o.text = '123.4';
      }
      else{
        o.y_start += 5;
      }
      a.push(o);
    }
  }
  if(a.length){
    for(let i = 1; i < 40; i++){
      let ii = w.round_to_3_places(i*step+t.wave_display_offset);
      if(i % 2 == 0){
          a[i-1].text = ii.toString();
      }
    }
  }
  return a;
}

export { draw_ticks }