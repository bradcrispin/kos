// set current vessel as ship var
// allow spacecraft to continue flight if change vessel
run initial.

// ISSUE
// cannot check if NEXTNODE exists without throwing uncatchable error
// this is a KOS bug to be fixed in next update

set nd to nextnode.
print "Orienting to burn vector.".
sas off.
// keep pointing straight when node prograde wavers at end
//local np is R(0,0,0) * nd:deltav.
//local np is nd:deltav.

lock g to this_ship:body:mu/(this_ship:body:radius + this_ship:altitude)^2.
local stageDV is getDV.
print("Burn dv: " + nd:deltav).
print("Stage dv: " + stageDV).


// lock steering to np.
lock steering to nd:burnvector.

if this_ship:maxthrust = 0 {
  print "No thrust!".
  sas on. // program will throw error
}

// vang(a,b) -> difference in angle between two vectors
wait until vang(this_ship:facing:vector, nd:burnvector) < 1.
wait 5.

local a0 is this_ship:maxthrust / this_ship:mass.
print "Max acceleration now: " + round(a0) + "m/s2".

// rocket equation: mass consumed linearly during burn
local engines_isp is 0.
list engines in engines_list.
for engine in engines_list {
  if engine:isp > 0 {
    set engines_isp to engines_isp + engine:maxthrust / this_ship:maxthrust * engine:isp.
  }

print "Engine ISP: " + round(engines_isp).
local Ve is engines_isp * this_ship:body:mu / (this_ship:body:radius + this_ship:altitude)^2.
local final_mass is mass * constant():e^(-1*nd:burnvector:mag/Ve).

// acc at time final
local a1 is this_ship:maxthrust / final_mass.
print "Max acceleration at burn end: " + round(a1) + "m/s2".

local burn_duration is nd:burnvector:mag / ((a0 + a1) / 2).

print "Burn duration: " + round(burn_duration) + " seconds.".

local start_time is time:seconds + nd:eta - burn_duration /2.
local end_time is time:seconds + nd:eta + burn_duration /2.

warpto(start_time - 30).

wait until time:seconds >= start_time.

print "Initiating maneuver burn.".

lock throttle to 1.
wait burn_duration.
//lock throttle to min(1/nd:deltav:mag, 0.1).

local done is false.
local dv0 is nd:deltav.

until done {
    if vdot(dv0, nd:deltav) < 0 {
        lock throttle to 0.
        break.
    }
    if nd:deltav:mag < 0.1 {
        wait until vdot(dv0, nd:deltav) < 0.2.
        lock throttle to 0.
        set done to true.
    }
    wait until true. // one physics tic.
}
local dvRemaining is getDV.
local dvBurned is stageDV - dvRemaining.
set dvTotal to dvTotal + dvBurned.
print("Circularization burn dv: " + round(dvBurned)).
print("Total burn dv: " + round(dvTotal)).
wait 3.
remove nd.
run return_controls.
}

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

LOCAL deltaV IS avgIsp * g * ln(SHIP:MASS / (SHIP:MASS-fuelMass)).
return deltaV.

}
