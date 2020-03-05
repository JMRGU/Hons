# Hons
Private repository for my Honours Project


// CURRENT STATE OF SOLUTION //
- proof of concept compiles
- placeBet() functions properly:
  - account provides an amount
- distributePrizes() bugged:
  - execution never enters loops, never raises count, refuses to pay to winners
  - something to do with a mismatch of address information in bettorInfo I think
  - does correctly assign win/lose amounts, and correctly reinitialize values
  
 // TO-DO LIST //
 - debug distributePrizes() (see above)
 - explore available sports APIs and integrate
 - consider alternate odds schemas; outcome matrices, additional complexity
 - deploy to test chain (not until much later?)
