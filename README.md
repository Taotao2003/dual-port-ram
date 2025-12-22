# Dual Port Ram Design and Verification
## Done in Cadence


Initially created in Summer 2025

First modify in Winter 2025


This is a WRITE THROUGH design with PORT B PRECEDENCE
- Write through means when a write happens, it updates the memory and the output

# Design

## Different Scenarios

if A and B reads:<br>
    Diff addr ==> A gets mem[addrA]; B gets mem[addrB]<br>
    Same addr ==> A gets mem[addr_]; B gets mem[addr_]<br>

if A writes and B reads:<br>
    Diff addr ==> mem[addrA] gets A and A gets A; B gets mem[addrB]<br> 
    Same addr ==> mem[addrA] gets A and A gets A; B gets old mem[addrA]<br>

if A reads and B writes:<br>
    Diff addr ==> A gets mem[addrA]; mem[addrB] gets B and B gets B<br>
    Same addr ==> mem[addrA] gets B and A gets B; B gets B<br>

if A and B writes:<br>
    Diff addr ==> mem[addrA] gets A and A gets A; mem[addrB] gets B and B gets B<br>
    Same addr ==> mem[addrA] gets B and A gets B; B gets B<br>

