parameter parachutes. // Bool

run initial.

if parachutes {

  // https://github.com/space-is-hard/kOS-Utils/blob/master/boot_kos_utils.ks
  //List that we'll store all of the parachute parts in
  SET chuteList TO LIST().

  //Gets all of the parts on the craft
  LIST PARTS IN partList.

  //Goes over the part list we just made
  FOR item IN partList {

      //Gets all of the modules of the part we're going over; local variable that gets
      //dumped every time the FOR loop is finished
      LOCAL moduleList TO item:MODULES.

      //Goes over moduleList to find the parachute module
      FOR module IN moduleList {

          //Checks the name of the module, and stores the part being gone over if the
          //parachute module shows up
          IF module = "ModuleParachute" {

              //Stores the part in the chuteList
              chuteList:ADD(item).
          }.
      }.
  }.
}.

print "Initiating landing protocol.".
local rad is this_ship:body:radius.
local mu is this_ship:body:mu.
local start_mass is this_ship:mass.

lock grav to (mu / (rad + this_ship:altitude)^2 ).
lock surface_grav to (mu / (rad + this_ship:altitude - alt:radar)^2 ).

lock leftoverThrust to ship:availablethrust - ((grav + surface_grav)/2 * this_ship:mass).

local touch_speed is -10.
local safety_dist is 10.
// d = v ^2 / 2a
lock stop_dist to ship:velocity:surface:mag^2 / ( 2 * max(0.001, leftoverThrust) / this_ship:mass).

local tStamp is 0.

lock throttle to 0.
set falling to false.

when this_ship:verticalspeed < -1 then {
  sas on.
  set sasmode to "retrograde". // just in case horizontal v
  set falling to true.
}

// PARACHUTES
if parachutes and leftoverThrust <= 0 {

    until alt:radar <= 1000 {
      clearscreen.
      print("Parachutes deploy mode") at (0,0).
      checkChutes.
      wait until true.
    }
} else {
// POWERED BURN
until alt:radar <= (stop_dist + safety_dist) {

  if time:seconds > (tStamp + 2) and falling {
    if parachutes {
      checkChutes.
    }.
    clearscreen.
    print("Burn alt " + round(stop_dist + safety_dist) + "meters") at (0, 2) .
    print("Suicide burn in " + round(alt:radar - (stop_dist + safety_dist)) + "meters") at (0, 4) .
  }
  wait until true.
}

clearscreen.
print "Suicide burn initiated".

lock throttle to this_ship:mass / start_mass.
print ("Deploying legs").
legs on.

until this_ship:verticalspeed >= touch_speed {
  if parachutes {
    checkChutes.
    print("Parachutes deploy mode") at (0,0).
  }
  print("Vertical speed: " + round(this_ship:verticalspeed)) at (0,2).
}

run land_pid.

clearscreen.
print "Landing complete".


}.




function checkChutes {

    //Determines whether we're in atmosphere, and below 10km, and descending
    IF SHIP:ALTITUDE < BODY:ATM:HEIGHT
        AND SHIP:ALTITUDE < 10000
        AND SHIP:VERTICALSPEED < -1 {

        //Goes over the chute list
        FOR chute IN chuteList {

            //Checks to see if the chute is already deployed
            IF chute:GETMODULE("ModuleParachute"):HASEVENT("Deploy Chute") {

                //Checks to see if the chute is safe to deploy
                IF chute:GETMODULE("ModuleParachute"):GETFIELD("Safe To Deploy?") = "Safe" {

                    //Deploy/arm this chute that has shown up as safe and ready
                    //to deploy
                    chute:GETMODULE("ModuleParachute"):DOACTION("Deploy", TRUE).

                    //Inform the user that we did so
                    print ("Parachutes deployed!") at (0,2).

                }.

            }.

        }.

    }.

}.
