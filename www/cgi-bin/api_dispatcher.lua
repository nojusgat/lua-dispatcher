local cjson = require "cjson"

local function send_response(response, status)
    local content_type = "text/html"
    if type(response) == "table" then
        content_type = "application/json"
        response = cjson.encode(response)
    end
    uhttpd.send("Status: " .. status .. "\r\n")
    uhttpd.send("Content-Type: " .. content_type .. "\r\n\r\n")
    uhttpd.send(response)
end

-- Main body required by uhhtpd-lua plugin
function handle_request(env)
    -- Injected uhttpd method
    local endpoint = require("endpoint")

    endpoint.send = send_response
    endpoint.env = env
    endpoint.decode = uhttpd.urldecode

    endpoint:handle_request()
end
