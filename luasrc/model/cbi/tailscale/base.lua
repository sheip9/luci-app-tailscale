m = Map("tailscale")
m.title = translate("Tailscale")
m.description = translate("Tailscale connects your team's devices and development environments for easy access to remote resources.") 

m:section(SimpleSection).template  = "tailscale/tailscale_status"    

s = m:section(NamedSection, 'settings', 'config');
s:tab("settings", translate("Basic Settings"))

o = s:taboption("settings", Flag, "enabled", translate("Enable"))
o.default = 0
o.rmempty = false

o = s:taboption("settings", Button, "Status", translate("Stauts"))
o.rawhtml = true
o.template = "tailscale/status_detail"

o = s:taboption("settings", Value, 'port', "Port", "Set the Tailscale port number.")
o.datatype = 'port'
o.default = '41641'
o.rmempty = false

o = s:taboption("settings", Value, 'config_path', "Workdir", "The working directory contains config files, audit logs, and runtime info.")
o.default = '/etc/tailscale'
o.rmempty = false

o = s:taboption("settings", ListValue, 'fw_mode', "Firewall Mode")
o:value("nftables", "nftables")
o:value("iptables", "iptables")
o.default = 'nftables'
o.rmempty = false


s:tab("advance", translate("Advanced Settings"));

o = s:taboption("advance", Flag, "acceptRoutes", translate("Accept Routes"), translate("Accept subnet routes that other nodes advertise."));
o.default = o.disabled;
o.rmempty = false;

o = s:taboption("advance", Value, "hostname", translate("Device Name"), translate("Leave blank to use the device's hostname."));
o.default = "";
o.rmempty = true;

o = s:taboption("advance", Flag, "acceptDNS", translate("Accept DNS"), translate("Accept DNS configuration from the Tailscale admin console."));
o.default = o.enabled;
o.rmempty = false;

o = s:taboption("advance", Flag, "advertiseExitNode", translate("Exit Node"), translate("Offer to be an exit node for outbound internet traffic from the Tailscale network."));
o.default = o.disabled;
o.rmempty = false;

s:tab("extra", translate("Extra Settings"));

o = s:taboption("extra", DynamicList, "flags", translate("Additional Flags"), translate("List of extra flags: Formas: --flags=value, e.g. <code>--exit-node=10.0.0.1</code>. <br> <a href='https://tailscale.com/kb/1241/tailscale-up' target='translateblank'>Available flags</a> for enabling settings upon the initiation of Tailscale."));
o.default = "";
o.rmempty = true;


s = m:section(NamedSection, "settings", "config");
s.title = translate("Custom Server Settings");
s.description = translate("Use <a href='https://github.com/juanfont/headscale' target='translateblank'>headscale</a> to deploy a private server.");

o = s:option(Value, "loginServer", translate("Server Address"));
o.default = "";
o.rmempty = true;

o = s:option(Value, "authKey", translate("Auth Key"));
o.default = "";
o.rmempty = true;


return m


