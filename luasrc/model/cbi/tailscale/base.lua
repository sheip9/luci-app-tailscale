a = Map("tailscale")
a.title = translate("Tailscale")
a.description = translate("Tailscale connects your team's devices and development environments for easy access to remote resources.") 

a:section(SimpleSection).template  = "tailscale/tailscale_status"    

t = a:section(TypedSection, "tailscale")
t.anonymous = true
t.addremove = false


t:tab("settings", translate("Basic Settings"))


e = t:taboption("settings", Flag, "enabled", translate("Enable"))
e.default = 0
e.rmempty = false

e = t:taboption("settings", Button, "Status", translate("Stauts"))
e.rawhtml = true
e.template = "tailscale/status_detail"

o = t:taboption("settings", Value, 'port', "Port", "Set the Tailscale port number.")
o.datatype = 'port'
o.default = '41641'
o.rmempty = false

o = t:taboption("settings", Value, 'config_path', "Workdir", "The working directory contains config files, audit logs, and runtime info.")
o.default = '/etc/tailscale'
o.rmempty = false

o = t:taboption("settings", ListValue, 'fw_mode', "Firewall Mode")
o:value("nftables", "nftables")
o:value("iptables", "iptables")
o.default = 'nftables'
o.rmempty = false


t:tab("advance", translate("Advanced Settings"));

o = t:taboption("advance", Flag, "acceptRoutes", translate("Accept Routes"), translate("Accept subnet routes that other nodes advertise."));
o.default = o.disabled;
o.rmempty = false;

o = t:taboption("advance", Value, "hostname", translate("Device Name"), translate("Leave blank to use the device's hostname."));
o.default = "";
o.rmempty = true;

o = t:taboption("advance", Flag, "acceptDNS", translate("Accept DNS"), translate("Accept DNS configuration from the Tailscale admin console."));
o.default = o.enabled;
o.rmempty = false;

o = t:taboption("advance", Flag, "advertiseExitNode", translate("Exit Node"), translate("Offer to be an exit node for outbound internet traffic from the Tailscale network."));
o.default = o.disabled;
o.rmempty = false;

t:tab("extra", translate("Extra Settings"));

o = t:taboption("extra", DynamicList, "flags", translate("Additional Flags"), translate("List of extra flagt: Format: --flags=value, e.g. <code>--exit-node=10.0.0.1</code>. <br> <a href='https://tailscale.com/kb/1241/tailscale-up' target='translateblank'>Available flags</a> for enabling settings upon the initiation of Tailscale."));
o.default = "";
o.rmempty = true;


s = a:section(NamedSection, "settings", "config");
s.title = translate("Custom Server Settings");
s.description = translate("Use <a href='https://github.com/juanfont/headscale' target='translateblank'>headscale</a> to deploy a private server.");

o = s:option(Value, "loginServer", translate("Server Address"));
o.default = "";
o.rmempty = true;

o = s:option(Value, "authKey", translate("Auth Key"));
o.default = "";
o.rmempty = true;


return a    
