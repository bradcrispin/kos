run initial.

run hohmann_calculations(target:altitude).
// returns transfer_dV: dv, transfer_duration: seconds


// calculate transfer_phase_angle

declare function get_transfer_phase_angle {
  local half_orbit_percent is (transfer_duration / (target:orbit:period / 2)).
    // degrees (from intersect point) = 180 * half_orbit_percent
    // degrees (from burn point) = 180 - degrees from intersect point
  return 180 - (180 * half_orbit_percent).
}

local transfer_phase_angle is get_transfer_phase_angle.
print("Transfer phase angle: " + round(transfer_phase_angle, 1) + " degrees").

// get universal angle

declare function get_universal_angle { // -> degrees
  parameter object.
  return (object:obt:lan + object:obt:argumentofperiapsis + object:obt:trueanomaly).
}

declare function get_phase_angle { // -> degrees
  parameter target.
  parameter this_ship.
  // ship angle to universal reference
  local angle is (get_universal_angle(target) - get_universal_angle(this_ship)).
  set angle to angle - 360 * floor(angle/360).
  return angle.
}

declare function get_phase_rate { // -> degrees / sec
  parameter target.
  parameter this_ship.

  local t0 is time:seconds.
  local phase_angle0 is get_phase_angle(target, this_ship).
  print("Current phase angle: "+ round(phase_angle0)).

  wait 0.1.
  local t1 is time:seconds.
  // want this global
  set phase_angle1 to get_phase_angle(target, this_ship).
  return abs((phase_angle1 - phase_angle0)/(t1 - t0)).
}

local phase_rate is get_phase_rate(target, this_ship).
print("Phase rate: " + round(phase_rate, 3) + " degrees / sec").

declare function get_time_until_burn {
  return (phase_angle1 - transfer_phase_angle) / phase_rate.
}

if transfer_phase_angle > phase_angle1 {
 print "Missed burn window. Setting for next opportunity.".
 set phase_angle1 to phase_angle1 + 360.
}

print("Transfer eta: " + round(get_time_until_burn/60, 1) + " minutes").

local burn_UT is time:seconds + get_time_until_burn.
set nd to node(burn_UT, 0, 0, transfer_dV).
add nd.
