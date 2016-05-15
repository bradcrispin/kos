parameter target_orbital_altitude.

// returns
local transfer_dV is 0. // dV
local transfer_duration is 0. // seconds

local M is this_ship:body:mu.
local R1 is 0.
local R2 is 0.

declare function get_dV {
  set R1 to this_ship:body:radius + this_ship:altitude.
  set R2 to this_ship:body:radius + target_orbital_altitude.
  return sqrt(M/R1) * ( sqrt( (2 * R2)/(R1 + R2) ) - 1).
}

set transfer_dV to get_dV.

if R2 > R1 {
  print("Transfer to higher orbit: " + round(target_orbital_altitude/1000) + "km").
}

if R2 < R1 {
  print("Transfer to lower orbit: " + round(target_orbital_altitude/1000) + "km").
}

print("First burn dV: " + round(transfer_dV, 1)).
print("Total dV: " + round((transfer_dV * 2), 1)).

// time to complete transfer.

set transfer_duration to constant:PI * sqrt( ((R1 + R2)^3) / (8 * M)).
print("Transfer time: " + round(transfer_duration/60, 1) + " minutes").
