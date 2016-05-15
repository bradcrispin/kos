run initial.

lock tgt_rel_pos to target:position * this_ship:facing:inverse.
lock steering to R(0,0,0) * target:position.

sas off.
rcs off.

until false {
  run vector_show.

  local t0 is time:seconds.
  local x0 is tgt_rel_pos:x.
  local y0 is tgt_rel_pos:y.
  local z0 is tgt_rel_pos:z.

  wait until true.

  local t1 is time:seconds.
  local x1 is tgt_rel_pos:x.
  local y1 is tgt_rel_pos:y.
  local z1 is tgt_rel_pos:z.

  local dt is t1 - t0.

  local x_rel is (x1 - x0)/dt.
  local y_rel is (y1 - y0)/dt.
  local z_rel is (z1 - z0)/dt.


  print ("Relative distance") at (0,0).
  print ("X: " + round(x1, 3)) at (0,2).
  print ("Y: " + round(y1, 3)) at (0,4).
  print ("Z: " + round(z1, 3)) at (0,6).

  print ("Relative velocity") at (0, 10).
  print ("X: " + round(x_rel, 3)) at (0,12).
  print ("Y: " + round(y_rel, 3)) at (0,14).
  print ("Z: " + round(z_rel, 3)) at (0,16).

  wait until true.
}
