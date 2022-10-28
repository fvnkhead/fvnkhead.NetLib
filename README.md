fvnkhead.NetLib
================================================================================

IPv4 functions for Northstar server modders, because the usual `player.GetIPString()`
gives you a string like:

    [::ffff:1.2.3.4]:1234

which is not ideal.

Either copy the code from [netlib.nut](mod/scripts/vscripts/netlib.nut)
or include this mod directly.

With:

  * `NL_GetPlayerIPv4String(player)`, you'll get `1.2.3.4`
  * `NL_GetPlayerIPv4NetworkString(player, 20)`, you'll get `1.2.0.0`,
which allows you to deal with the network range a player is in.

Use cases
--------------------------------------------------------------------------------

Kicking and/or banning spoofed players by their IPv4 network instead of UIDs,
which forces them to switch networks and thus making consecutive cheating more
frustrating.

If you include this mod, it also prints a player's name, UID and IP address
at every client connect, like this:

```
[04:05:12] [info] [SERVER SCRIPT] [fvnkhead.NetLib] client connected: 'foobar'/001231045/1.2.3.4
```

Mod integration
--------------------------------------------------------------------------------

Add a [dependency constant](https://r2northstar.readthedocs.io/en/latest/reference/northstar/dependencyconstants.html)
in your mod's `mod.json`, eg.:

```
"Dependencies": {
    "NETLIB": "fvnkhead.NetLib"
}
```

Then in your code, use you can use conditional compilation like this:

```
   string playerId = player.GetUID()
#if NETLIB
   playerId = NL_GetPlayerIPv4NetworkString(player, 20)
   KickPlayersByNetwork(playerId)
   return
#endif
   KickPlayerByUID(playerId)
```

Reference
--------------------------------------------------------------------------------

### Player functions

#### `string function NL_GetPlayerIPv4String(entity player)`

Returns the player's IPv4 address as a string, or `""` on error. (should not fail)

#### `int function NL_GetPlayerIPv4Int(entity player)`

Returns the player's IPv4 as an integer, or `-1` on error. (should not fail)

#### `string function NL_GetPlayerIPv4NetworkString(entity player, int cidr)`

Returns the player's network as a string, with the `cidr` value denoting the size of the
subnet. Eg. with `cidr=24`, both `1.2.3.50` and `1.2.3.100` would result into
`1.2.3.0`, because that matches 256 hosts. See [this](https://www.connecteddots.online/resources/blog/subnet-masks-table) for more information.

Recommended CIDR value for kicking/banning people is around 18-24. With 16, you'll match 65,536 hosts, which can start affecting normal players.

#### `int function NL_GetPlayerIPv4NetworkInt(entity player, int cidr)`

Returns the player's network as an integer.

#### `string function NL_GetPlayerDescription(entity player)`

Returns a descriptive player string that has the name (in quotes), UID and IP address.

Example: `'PubStomper69'/900192228/1.2.3.4`

### Conversion functions

#### `int function NL_IPv4StringToInt(string addrStr)`

Converts an IPv4 string into an integer.

#### `string function NL_IPv4IntToString(int addrInt)`

Converts an IPv4 integer to a string.

### Other

#### `int function NL_GetIPv4SubnetMask(int cidr)`

Returns an integer subnet mask with `cidr` as the range.

#### `int function NL_IPv4IntToNetwork(int addr, int subnet)`

Converts an integer address to a network with the given subnet.

#### `bool function NL_IsIPv4String(string addr)`

Returns `true` if the given string is a valid IPv4 address, `false` otherwise.
