set this_ship to ship.
set ui_delay to 0.5.

clearscreen.
print "Running preflight checks.".

set done to false.

until done {

  set g to ( this_ship:body:mu / (this_ship:body:radius + this_ship:altitude)^2 ).
  set twr to this_ship:maxthrust / (this_ship:mass * g).

  wait ui_delay.
  print "TWR: " + round(twr, 2).

  if twr = 0 {
    wait ui_delay.
    print "Activate first stage engines at zero throttle for testing.".
    wait ui_delay.
    // set done to true.
    break.
  }

  if twr < 1 {
    wait ui_delay.
    print "First stage propulsion TWR < 1.".
    // set done to true.
    wait ui_delay.
    break.
  } else {
    wait ui_delay.
    print "First stage propulsion is nominal.".
  }

  // ...
  wait ui_delay.
  print "All systems go. Ready for launch.".
  wait ui_delay + 1.
  clearscreen.
  set done to true.
}
