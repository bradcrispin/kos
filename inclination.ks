parameter target_inclination. // : degrees

run initial.

local inclination is this_ship:obt:inclination.
print("Inclination: " + round(inclination, 3) + " degrees").

local dI is target_inclination - inclination.
local v is this_ship:velocity:orbit:mag.

local dV is 2 * v * sin(dI/2).
print("dV burn to normal: " + round(dV, 1) + "dV").

local t0 is time:seconds.
local lat0 is this_ship:geoposition:lat.
wait 1.
local t1 is time:seconds.
local lat1 is this_ship:geoposition:lat.

if abs(lat1) < abs(lat0) {
    print "Approaching equatorial node".

    local rate_lat_change is (abs(lat0) - abs(lat1)) / (t1 - t0).

    if rate_lat_change > 0.005 {
      local eta_lat_is_0 is abs(lat1) / rate_lat_change.
      print("Rate lat change: " + rate_lat_change).

      if lat1 > 0 {
        print "Descending node".
        set nd to node(time:seconds + eta_lat_is_0, 0, -dV, 0).
        add nd.
      } else {
        print "Ascending node".
        set nd to node(time:seconds + eta_lat_is_0, 0, dV, 0).
        add nd.
      }

      print("ETA next equatorial node: " + eta_lat_is_0).
    } else {
    print("Rate lat change too low to calculate maneuver.").
    print("Wait a bit longer.").
    }


} else {
  print "Moving away from equatorial node. Just wait man.".
}


// if latitude moving towards zero, we are going up
// next inclination node is ascending
// burn to anti normal
