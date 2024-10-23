require("luci.util")
local json = require "luci.jsonc"
local sys = require "luci.sys"
local text = sys.exec("tailscale status --json")
local tailStatus = json.parse(text)
local onlineExitNodes = {}
local subnetRoutes = {}
if tailStatus ~= nil and tailStatus.Peer ~= nil then
    for _, peer in pairs(tailStatus.Peer) do  
        if peer.PrimaryRoutes ~= nil then
            for _, sub in pairs(peer.PrimaryRoutes) do
                table.insert(subnetRoutes, sub)
            end
        end
        if peer.ExitNodeOption and peer.Online then
            table.insert(onlineExitNodes, peer.HostName)  
        end  
    end 
end
 function callInterfaceStatus(interfaceName)  
    return  luci.util.ubus(string.format("network.interface.%s", interfaceName), "status") 
 end  

function ipToBinary(ip)  
    local octets = {}
    for octet in string.gmatch(ip, "(%d+)") do  
        table.insert(octets, octet)  
    end  
    local binary_string = ""  
    for _, octet in ipairs(octets) do  
        local decimal = tonumber(octet)  
        local binary = ""  
        while decimal > 0 do  
            local bit = decimal % 2  
            binary = tostring(bit) .. binary  
            decimal = math.floor(decimal / 2)  
        end  
        while #binary < 8 do  
            binary = "0" .. binary  
        end  
        binary_string = binary_string .. binary  
    end  
    return binary_string  
end  

function calculateSubnetAndCIDR(ip, cidr)  
    local cidrInt = tonumber(cidr)  
    local maskBinary = string.rep("1", cidrInt):sub(1, cidrInt) .. string.rep("0", 32 - cidrInt)  
    local ipBinary = ipToBinary(ip)  
    local subnetBinary = ""  
    for i = 1, 32 do  
        if ipBinary:sub(i, i) == "1" and maskBinary:sub(i, i) == "1" then  
            subnetBinary = subnetBinary .. "1"  
        else  
            subnetBinary = subnetBinary .. "0"  
        end  
    end  
    local subnetOctets = {}  
    for i = 1, 4 do  
        local octet = tonumber(subnetBinary:sub((i-1)*8 + 1, i*8), 2)  
        table.insert(subnetOctets, string.format("%d", octet))  
    end  
    local subnet = table.concat(subnetOctets, ".")  
    return string.format("%s/%d", subnet, cidrInt)  
end  

function getInterfaceSubnets(interfaces)  
    if not interfaces then  
        interfaces = {"lan", "wan"}  
    end  
    local interfaceSubnets = {}  
    local function processInterface(interfaceName)  
        local status = callInterfaceStatus(interfaceName)
        local ipv4Addresses = status["ipv4-address"] or {}  
        for _, addr in ipairs(ipv4Addresses) do 
            local subnet = calculateSubnetAndCIDR(addr.address, addr.mask)  
            if not tableHasItem(interfaceSubnets, subnet) then  
                table.insert(interfaceSubnets, subnet)  
            end  
        end  
    end  
    for _, interfaceName in ipairs(interfaces) do  
        processInterface(interfaceName)  
    end   
    return interfaceSubnets  
end  

function tableHasItem(t, item)  
    for _, v in ipairs(t) do  
        if v == item then  
            return true  
        end  
    end  
    return false  
end 

local interfaceSubnets = getInterfaceSubnets()

m = Map("tailscale")
m.title = translate("Tailscale")
m.description = translate("Tailscale connects your team's devices and development environments for easy access to remote resources.") 

m:section(SimpleSection).template  = "tailscale/tailscale_status"    

s = m:section(NamedSection, "settings", "config")
s:tab("settings", translate("Basic Settings"))

o = s:taboption("settings", Flag, "enabled", translate("Enable"))
o.default = 0
o.rmempty = false

o = s:taboption("settings", Button, "Status", translate("Stauts"))
o.rawhtml = true
o.template = "tailscale/status_detail"

o = s:taboption("settings", Value, "port", "Port", "Set the Tailscale port number.")
o.datatype = "port"
o.default = "41641"
o.rmempty = false

o = s:taboption("settings", Value, "config_path", "Workdir", "The working directory contains config files, audit logs, and runtime info.")
o.default = "/etc/tailscale"
o.rmempty = false

o = s:taboption("settings", ListValue, "fw_mode", "Firewall Mode")
o:value("nftables", "nftables")
o:value("iptables", "iptables")
o.default = "nftables"
o.rmempty = false

s:tab("advance", translate("Advanced Settings"))

o = s:taboption("advance", Flag, "acceptRoutes", translate("Accept Routes"), translate("Accept subnet routes that other nodes advertise."))
o.default = o.disabled
o.rmempty = false

o = s:taboption("advance", Value, "hostname", translate("Device Name"), translate("Leave blank to use the device's hostname."))
o.default = ""
o.rmempty = true

o = s:taboption("advance", Flag, "acceptDNS", translate("Accept DNS"), translate("Accept DNS configuration from the Tailscale admin console."))
o.default = o.enabled
o.rmempty = false

o = s:taboption("advance", Flag, "advertiseExitNode", translate("Exit Node"), translate("Offer to be an exit node for outbound internet traffic from the Tailscale network."))
o.default = o.disabled
o.rmempty = false

o = s:taboption("advance", ListValue, "exitNode", translate("Online Exit Nodes"), translate("Select an online machine name to use as an exit node."))
if #onlineExitNodes > 0 then  
    o.value(o, "", translate("-- Please choose --"))  
    for _, node in ipairs(onlineExitNodes) do  
        o.value(o, node, node)  
    end  
else  
    o.value(o, "", translate("No Available Exit Nodes"))  
    o.readonly = true  
end  
o.default = ""
o:depends("advertiseExitNode", "0")
o.rmempty = true

o = s:taboption("advance", DynamicList, "advertiseRoutes", translate("Expose Subnets"), translate("Expose physical network routes into Tailscale, e.g. <code>10.0.0.0/24</code>."))
if #interfaceSubnets > 0 then  
    for _, subnet in ipairs(interfaceSubnets) do  
        o.value(o, subnet, subnet)
    end  
end
o.default = ""
o.rmempty = true

o = s:taboption("advance", Flag, "s2s", translate("Site To Site"), translate("Use site-to-site layer 3 networking to connect subnets on the Tailscale network."))
o.default = o.disabled
o:depends("acceptRoutes", "1")
o.rmempty = false

o = s:taboption("advance", DynamicList, "subnetRoutes", translate("Subnet Routes"), translate("Select subnet routes advertised by other nodes in Tailscale network."))
if #subnetRoutes > 0 then  
    for _, route in ipairs(subnetRoutes) do  
        o.value(o, route, route)
    end  
else  
    o.value(o, "", translate("No Available Subnet Routes"))  
    o.readonly = true  
end  
o.default = ""
o:depends("s2s", "1")
o.rmempty = true

o = s:taboption("advance", MultiValue, "access", translate("Access Control"))
o:value("tsfwlan", translate("Tailscale access LAN"))
o:value("tsfwwan", translate("Tailscale access WAN"))
o:value("lanfwts", translate("LAN access Tailscale"))
o:value("wanfwts", translate("WAN access Tailscale"))
o.default = "tsfwlan tsfwwan lanfwts"
o.rmempty = true

s:tab("extra", translate("Extra Settings"))

o = s:taboption("extra", DynamicList, "flags", translate("Additional Flags"), translate("List of extra flags: Formas: --flags=value, e.g. <code>--exit-node=10.0.0.1</code>. <br> <a href='https://tailscale.com/kb/1241/tailscale-up' target='translateblank'>Available flags</a> for enabling settings upon the initiation of Tailscale."))
o.default = ""
o.rmempty = true

s = m:section(NamedSection, "settings", "config")
s.title = translate("Custom Server Settings")
s.description = translate("Use <a href='https://github.com/juanfont/headscale' target="translateblank">headscale</a> to deploy a private server.")

o = s:option(Value, "loginServer", translate("Server Address"))
o.default = ""
o.rmempty = true

o = s:option(Value, "authKey", translate("Auth Key"))
o.default = ""
o.rmempty = true

return m
