local cjson = require "cjson"

local function add_string(stack, s)
    table.insert(stack, s) -- push 's' into the the stack
    for i = #stack - 1, 1, -1 do
        if string.len(stack[i]) > string.len(stack[i + 1]) then
            break
        end
        stack[i] = stack[i] .. table.remove(stack)
    end
end

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

local function parse_incoming_data(headers, buffer)
    if headers["content-type"] == "application/json" then
        local status, data = pcall(cjson.decode, buffer)
        if not status then
            send_response({ error = "Invalid json" }, "400 Bad Request")
            os.exit()
        else
            return data
        end
    end

    if headers["content-type"] == "application/x-www-form-urlencoded" then
        local status, data = pcall(parse_query_string, buffer)
        if not status then
            send_response({ error = "Invalid form data" }, "400 Bad Request")
            os.exit()
        else
            return data
        end
    end

    return buffer
end

-- JWT secret key
local JWT_SECRET_KEY = "random_key"
-- Maximum allowed content length
local LARGEST_CONTENT_LENGTH = 1048576

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

    env.query = parse_query_string(env.QUERY_STRING)
    env.auth_headers = parse_authorization_header(env.headers)

    local recv_len = tonumber(env.CONTENT_LENGTH) or 0
    local function recv()
        if recv_len > LARGEST_CONTENT_LENGTH then
            return send_response({ error = "Content too large" }, "413 Content Too Large")
        end

        local buf = { "" }
        while recv_len > 0 do
            local rlen, rbuf = uhttpd.recv(4096)
            recv_len = recv_len - rlen
            add_string(buf, rbuf)
        end
        buf = table.concat(buf)

        if string.len(buf) > 0 then
            return parse_incoming_data(env.headers, buf)
        end

        return nil
    end

    endpoint:new(recv, send_response, env, JWT_SECRET_KEY)
    if endpoint.init then
        endpoint:init()
    end
    endpoint:handle_request()
end
