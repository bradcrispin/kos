parameter orbit_altitude. // "80"
parameter inclination. // 0 - 365

run initial.
local ui_delay is 0.5.

set orbit_altitude to orbit_altitude * 1000.

// start launch
clearscreen.
print "Launch protocol initiated.".
print "Target orbit altitude: " + round(orbit_altitude)/1000 + "km".
print "Target inclination: " + round(inclination, 2) + " degrees".
wait ui_delay.

local thrott is 1.
lock throttle to thrott.

lock g to this_ship:body:mu/(this_ship:body:radius + this_ship:altitude)^2.
lock twr to this_ship:maxthrust / (this_ship:mass * g).

print "Target orbital altitude: " + round(orbit_altitude) + ".".

// solar panel check - this affects all panels
if panels {
  print "Retracting solar panels for launch.".
  toggle panels.
  wait 5.
}

// set up initial launch
local compass_heading is (90 - inclination).

// ascent profile: a nice curve
lock target_pitch to max( (90 - this_ship:altitude/1000 * 2.5), 0).
lock steering to heading(compass_heading, target_pitch).
sas on.

// initial stage
stage.
local newStage is false.
local dvStage is getDV. // initial
global dvTotal is 0. // consumed, used across programs

// staging logic
when this_ship:maxthrust = 0 then {
  print "Staging.".
  stage.
  set newStage to true.
  preserve.
}

// main launch loop
local t0 is time:seconds.

// configure PID
set pid to pidloop(0.2, 0.006, 0.006).
//set pid to pidloop(0.01, 0.006, 0.006).

// target maxq of 10k
set pid:setpoint to .14. //q
set limit to 0.005.
set pid:maxoutput to limit.
set pid:minoutput to -limit.



set this_ship:control:pilotmainthrottle to 0. // for returning control
set dthrott to 0.

local t0 is time:seconds.

until this_ship:apoapsis >= orbit_altitude {

  if newStage {
    set dvTotal to dvTotal + dvStage. // full stage used
    set newStage to false.
    set dvStage to getDV.
  }

  if time:seconds > (t0) {

    set dthrott to pid:update(time:seconds, this_ship:q).
    set thrott to max(0, min(1, thrott + dthrott)).
    wait until true. // one tic.
  }

  //HUD
  clearscreen.
  print ("Setpoint: " + round(pid:setpoint,2) + "q") at (0,2).
  print("Throttle: " + round(thrott, 2)) at (0,4).
  print("DThrottle: " + round(dthrott, 3)) at (0,6).

  print "Heading: " + round(this_ship:heading, 2) at (0,10).
  print "Inclination: " + round(this_ship:obt:inclination, 2) at (0,12).
  print "Velocity: " + round(this_ship:airspeed) at (0,14).
  print "TWR: " + round(twr, 2) at (0,16).
  print "Q: " + round(this_ship:q, 2) at (0,18).
  print "Altitude: " + round(this_ship:altitude) at (0,20).
  print "Apoapsis: " + round(this_ship:apoapsis) at (0,22).
  print "Stage DV remaining: " + round(getDV) at (0,26).

  wait until true. // main loop once per physics tick.
}
clearscreen.
print "Target apoapsis reached.".
run dv.
// stage.
set thrott to 0.
set this_ship:control:pilotmainthrottle to 0.

until this_ship:altitude >= this_ship:body:atm:height {
  wait until true.
}

if panels {
  print "Solar panels are already deployed".
} else {
  print "Escaped atmosphere. Deploying solar panels.".
  run solar.
}
print "Launch protocol terminating.".
local dvRemaining is getDV.
local dvBurned is dvStage - dvRemaining.
set dvTotal to dvTotal + dvBurned.
print "Total dv burned: " + round(dvTotal).
print "Stage dv remaining: " + round(dvRemaining).
wait 3.

run circularize.

function getDV {
// https://www.reddit.com/r/Kos/comments/330yir/calculating_stage_deltav/

// fuel name list
LOCAL fuels IS list().
fuels:ADD("LiquidFuel").
fuels:ADD("Oxidizer").
fuels:ADD("SolidFuel").
fuels:ADD("MonoPropellant").

// fuel density list (order must match name list)
LOCAL fuelsDensity IS list().
fuelsDensity:ADD(0.005).
fuelsDensity:ADD(0.005).
fuelsDensity:ADD(0.0075).
fuelsDensity:ADD(0.004).

// initialize fuel mass sums
LOCAL fuelMass IS 0.

// calculate total fuel mass
FOR r IN STAGE:RESOURCES
{
    LOCAL iter is 0.
    FOR f in fuels
    {
        IF f = r:NAME
        {
            SET fuelMass TO fuelMass + fuelsDensity[iter]*r:AMOUNT.
        }.
        SET iter TO iter+1.
    }.
}.

// thrust weighted average isp
LOCAL thrustTotal IS 0.
LOCAL mDotTotal IS 0.
LIST ENGINES IN engList.
FOR eng in engList
{
    IF eng:IGNITION
    {
        LOCAL t IS eng:maxthrust*eng:thrustlimit/100. // if multi-engine with different thrust limiters
        SET thrustTotal TO thrustTotal + t.
        IF eng:ISP = 0 SET mDotTotal TO 1. // shouldn't be possible, but ensure avoiding divide by 0
        ELSE SET mDotTotal TO mDotTotal + t / eng:ISP.
    }.
}.
IF mDotTotal = 0 LOCAL avgIsp IS 0.
ELSE LOCAL avgIsp IS thrustTotal/mDotTotal.

// deltaV calculation as Isp * g0 * ln(m0/m1).

LOCAL deltaV IS avgIsp * 9.81 * ln(SHIP:MASS / (SHIP:MASS-fuelMass)).
return deltaV.

}
