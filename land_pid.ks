run initial.

sas on.
set sasmode to "retrograde". // just in case horizontal v

// configure PID
//set pid to pidloop(0.156, 0.101, 0.060).
set pid to pidloop(0.01, 0.006, 0.006).


set limit to 0.05.
set pid:maxoutput to limit.
set pid:minoutput to -limit.

set thrott to 1.
lock throttle to thrott.
lock dthrott to pid:update(time:seconds, ship:verticalspeed).

set this_ship:control:pilotmainthrottle to 0. // for returning control

local t0 is time:seconds.

until this_ship:status = "LANDED" or this_ship:status = "SPLASHED"{
  if time:seconds > (t0) {
    set pid:setpoint to max(-10, -alt:radar). // m/s
    print ("Setpoint" + round(pid:setpoint)) at (0,2).
    print (round(alt:radar) + " m") at (0,4).
    print("Throttle: " + round(thrott, 1)) at (0,6).
    print("DThrottle: " + round(dthrott, 3)) at (0,8).
    set thrott to max(0, min(1, thrott + dthrott)).
    wait until true. // one tic.
  }

}
