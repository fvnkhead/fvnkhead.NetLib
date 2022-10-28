global function NL_Init;

global function NL_GetPlayerIPv4String;
global function NL_GetPlayerIPv4Int;
global function NL_GetPlayerIPv4NetworkString;
global function NL_GetPlayerIPv4NetworkInt;
global function NL_GetPlayerDescription;

global function NL_IPv4StringToInt;
global function NL_IPv4IntToString;

global function NL_GetIPv4SubnetMask;
global function NL_IPv4IntToNetwork;

global function NL_IsIPv4String;

//-------------------------------------------------------------------------------- 
// Public
//-------------------------------------------------------------------------------- 

void function NL_Init()
{
    AddCallback_OnClientConnected(OnClientConnected)
    RunTests()
}

string function NL_GetPlayerIPv4String(entity player)
{
    if (!IsValid(player)) {
        return ""
    }

    string raw = player.GetIPString()

    // shouldn't happen but
    if (raw == "") {
        LogPlayerIPv4ParseError(player)
        return ""
    }

    // "[::ffff:1.2.3.4]:1234" => ("[::ffff:1.2.3.4", "]:1234")
    array<string> parts = split(raw, "]")
    if (parts.len() != 2) {
        LogPlayerIPv4ParseError(player)
        return ""
    }

    // "[::ffff:1.2.3.4" => ("[", "ffff", "1.2.3.4")
    parts = split(parts[0], ":")
    if (parts.len() != 3) {
        LogPlayerIPv4ParseError(player)
        return ""
    }

    string addr = parts[2]
    if (!NL_IsIPv4String(addr)) {
        LogPlayerIPv4ParseError(player)
        return ""
    }

    return strip(addr)
}

int function NL_GetPlayerIPv4Int(entity player)
{
    string addrStr = NL_GetPlayerIPv4String(player)
    if (addrStr == "") {
        return -1
    }

    return NL_IPv4StringToInt(addrStr)
}

int function NL_GetPlayerIPv4NetworkInt(entity player, int cidr)
{
    int addr = NL_GetPlayerIPv4Int(player)
    if (addr == -1) {
        return -1
    }

    int subnet = NL_GetIPv4SubnetMask(cidr)
    int network = NL_IPv4IntToNetwork(addr, subnet)

    return network
}

string function NL_GetPlayerIPv4NetworkString(entity player, int cidr)
{
    int networkInt = NL_GetPlayerIPv4NetworkInt(player, cidr)
    if (networkInt == -1) {
        return ""
    }

    return NL_IPv4IntToString(networkInt)
}

int function NL_IPv4StringToInt(string addrStr)
{
    if (!NL_IsIPv4String(addrStr)) {
        return -1
    }

    int addrInt = 0
    array<string> parts = split(addrStr, ".")

    int oct = parts[3].tointeger()
    addrInt = addrInt | (oct << 0)

    oct = parts[2].tointeger()
    addrInt = addrInt | (oct << 8)

    oct = parts[1].tointeger()
    addrInt = addrInt | (oct << 16)

    oct = parts[0].tointeger()
    addrInt = addrInt | (oct << 24)

    return addrInt
}

string function NL_IPv4IntToString(int addrInt)
{
    int oct1 = (addrInt >> 24) & 0xFF
    int oct2 = (addrInt >> 16) & 0xFF
    int oct3 = (addrInt >> 8)  & 0xFF
    int oct4 = (addrInt >> 0)  & 0xFF

    string addrStr = format("%d.%d.%d.%d", oct1, oct2, oct3, oct4)
    return addrStr
}

int function NL_GetIPv4SubnetMask(int cidr)
{
    return -1 ^ ((1 << 32 - cidr) - 1)
}

int function NL_IPv4IntToNetwork(int addr, int subnet)
{
    return addr & subnet
}

bool function NL_IsIPv4String(string addr)
{
    array<string> parts = split(addr, ".")
    if (parts.len() != 4) {
        return false
    }

    foreach (string part in parts) {
        if (!IsInt(part)) {
            return false
        }

        int oct = part.tointeger()
        if (!IsOctet(oct)) {
            return false
        }
    }

    return true
}

string function NL_GetPlayerDescription(entity player)
{
    if (!IsValid(player)) {
        return ""
    }

    return format("'%s'/%s/%s", player.GetPlayerName(), player.GetUID(), NL_GetPlayerIPv4String(player))
}

//-------------------------------------------------------------------------------- 
// Private
//-------------------------------------------------------------------------------- 

void function OnClientConnected(entity player)
{
    Log("client connected: " + NL_GetPlayerDescription(player))
}

bool function IsInt(string num)
{
    for (int i = 0; i < num.len(); i++) {
        if (expect int(num[i]) < 48 || expect int(num[i]) > 57) {
            return false
        }
    }

    try {
        num.tointeger()
        return true
    } catch (ex) {
        return false
    }
}

bool function IsOctet(int num)
{
    return 0 <= num && num <= 255
}

void function LogPlayerIPv4ParseError(entity player)
{
    string ip = player.GetIPString()
    string ign = player.GetPlayerName()
    string uid = player.GetUID()
    string msg = format("cannot parse IPv4 string '%s' from player '%s' (%s)", ip, ign, uid)
    Log(msg)
}

void function Log(string msg)
{
    print("[fvnkhead.NetLib] " + msg)
}

//-------------------------------------------------------------------------------- 
// Tests
//-------------------------------------------------------------------------------- 

void function RunTests()
{
    TestValidIPv4Strings()
    TestInvalidIPv4Strings()
    TestStringConversions()
    TestSubnets()
}

array<string> validIPv4Strings = [
    "0.0.0.0",
    "1.2.3.4",
    "1.23.45.255"
]

void function TestValidIPv4Strings()
{
    foreach (string ip in validIPv4Strings) {
        if (!NL_IsIPv4String(ip)) {
            // assertions didnt work for some reason
            Log("[TestValidIPv4Strings] test failure: " + ip)
        }
    }
}

void function TestStringConversions()
{
    foreach (string ip in validIPv4Strings) {
        string converted = NL_IPv4IntToString(NL_IPv4StringToInt(ip))
        if (ip != converted) {
            Log("[TestStringConversions] test failure: " + ip + " != " + converted)
        }
    }
}

void function TestSubnets()
{
    array< array<string> > entries = [
        ["192.168.0.1", "24", "192.168.0.0" ],
        ["12.34.56.78", "20", "12.34.48.0"  ],
        ["192.168.0.1", "16", "192.168.0.0" ],
        ["12.34.56.78", "10", "12.0.0.0"    ],
        ["192.168.0.1", "8",  "192.0.0.0"   ],
    ]

    foreach (array<string> entry in entries) {
        int addrIp = NL_IPv4StringToInt(entry[0])
        int mask = NL_GetIPv4SubnetMask(entry[1].tointeger())
        string network = NL_IPv4IntToString(NL_IPv4IntToNetwork(addrIp, mask))
        if (network != entry[2]) {
            Log("[TestSubnets] test failure: " + entry[0] + " " + entry[1] + " != " + entry[2])
        }
    }
}

array<string> invalidIPv4Strings = [
    "foobar",
    "255.255.255.256",
    "-1.0.0.0",
    "1.2.foo.4",
    "ffff:ffff:ffff:ffff:ffff",
    "1.2.3",
    "1.2.3.4.5"
]

void function TestInvalidIPv4Strings()
{
    foreach (string ip in invalidIPv4Strings) {
        if (NL_IsIPv4String(ip)) {
            Log("[TestInvalidIPv4Strings] test failure: " + ip)
        }
    }
}
