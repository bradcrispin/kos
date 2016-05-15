run initial.

print "Creating maneuver node for circularization burn.".

// check what is next node
if eta:apoapsis <= eta:periapsis {
  set eta_burn to eta:apoapsis.
  set target_alt to this_ship:apoapsis.
} else {
  set eta_burn to eta:periapsis.
  set target_alt to this_ship:periapsis.
}

local v0 is velocityat(this_ship, (time:seconds + eta_burn)):orbit:mag.
print "Predicted velocity: " + round(v0).

local v1 is sqrt(this_ship:body:mu/(this_ship:body:radius + target_alt)).
print "Required velocity: " + round(v1).

local dV is v1 - v0.
print "Creating maneuver node: " + round(dV) + "dV in " + round(eta_burn) + " seconds".

set nd to node( (time:seconds + eta_burn), 0, 0, dV).
add nd.

run next_node.
