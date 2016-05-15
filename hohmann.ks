//  TODO refactor hohmann and intercept with shared logic
// diff is altitude of a target vs a target altitude

parameter target_orbital_altitude. // :meters

run initial.

run hohmann_calculations(target_orbital_altitude).
// returns transfer_dv: dv, transfer_duration: seconds

set nd to node(time:seconds + 30, 0, 0, transfer_dv).
add nd.

run next_node.
