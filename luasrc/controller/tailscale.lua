module("luci.controller.tailscale", package.seeall)
require("luci.util")

function index()
        if not nixio.fs.access("/etc/config/tailscale") then
                return
        end

entry({"admin","vpn"}, firstchild(), "VPN", 45).dependent = false
entry({"admin", "vpn", "tailscale"}, alias("admin", "vpn", "tailscale", "base"), _("Tailscale"), 99)
entry({"admin", "vpn", "tailscale", "base"}, cbi("tailscale/base"), _("Base Setting"), 1)
entry({"admin", "vpn", "tailscale", "status"}, call("act_status"))
entry({"admin", "vpn", "tailscale", "status_detail"}, call("status_detail"))
end

function act_status()
        local e = {}
        local text = luci.util.ubus("service", "list")
        luci.http.prepare_content("application/json")
        if text.tailscale.instances == nil then
                e.running = false
                luci.http.write_json(e)
                return
        end
        e.running = text.tailscale.instances.instance1.running
        luci.http.write_json(e)
end


function status_detail()
        local json = require "luci.jsonc"
        local sys = require "luci.sys"
        local text = sys.exec("tailscale status --json")
        luci.http.prepare_content("application/json")
        local m = json.parse(text)
        luci.http.write_json(m)

end
