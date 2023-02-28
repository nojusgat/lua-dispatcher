local cjson = require "cjson"

local function prequire(...)
    local status, lib = pcall(require, ...)
    if status then
        return lib
    end
    return nil
end

local function remove_last_slash(uri)
    if string.sub(uri, -1) == "/" then
        return remove_last_slash(string.sub(uri, 1, -2))
    end
    return uri
end

local function parse_request_uri(uri)
    local path = string.match(uri, "^/api/*(.*)")
    local parameters_start = string.find(path, "?")
    if parameters_start ~= nil then
        path = remove_last_slash(string.sub(path, 1, parameters_start - 1))
    else
        path = remove_last_slash(path)
    end
    path = uhttpd.urldecode(path)
    path = string.gsub(path, "/+", ".")
    path = string.gsub(path, " +", "_")
    path = string.lower(path)
    return path
end

local function parse_query_string(query)
    local values = {}
    for key, val in string.gmatch(query, "([^&=]+)(=*[^&=]*)") do
        local d_key = uhttpd.urldecode(key)
        local d_val = uhttpd.urldecode(val)
        d_key = d_key:gsub('=+.*$', "")
        d_key = d_key:gsub('%s', "_")
        d_val = d_val:gsub('^=+', "")

        values[d_key] = d_val
    end
    return values
end

local function parse_authorization_header(headers)
    local auth = {}
    local header = headers["authorization"]
    if header ~= nil then
        local token_type, token = string.match(header, "(%S+) (%S+)")
        if token_type ~= nil and token ~= nil then
            auth.type = token_type
            auth.token = token
        end
    end
    return auth
end

local function send_response(response, status)
    local content_type = "text/html"
    if type(response) == "table" then
        content_type = "application/json"
        response = cjson.encode(response)
    end
    if status == nil then
        status = "200 OK"
    end
    uhttpd.send("Status: " .. status .. "\r\n")
    uhttpd.send("Content-Type: " .. content_type .. "\r\n\r\n")
    uhttpd.send(response)
end

-- Main body required by uhhtpd-lua plugin
function handle_request(env)
    local path = parse_request_uri(env.REQUEST_URI)
    if path == "" then
        return send_response({ error = "Not Found" }, "404 Not Found")
    end

    local endpoint = prequire("endpoints." .. path)
    if not endpoint then
        return send_response({ error = "Not Found" }, "404 Not Found")
    end

    local query = parse_query_string(env.QUERY_STRING)
    local authorization = parse_authorization_header(env.headers)

    env.query = query
    env.auth_headers = authorization

    endpoint:new(send_response, env)
    endpoint:handle_request()
end
