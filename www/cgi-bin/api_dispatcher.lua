cjson = require "cjson"
Endpoint = require "endpoint"
UCIOrm = require "uciorm"

local STATUS_MESSAGES = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [226] = "IM Used",
    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Content Too Large",
    [414] = "URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Range Not Satisfiable",
    [417] = "Expectation Failed",
    [421] = "Misdirected Request",
    [422] = "Unprocessable Content",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [425] = "Too Early",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [451] = "Unavailable For Legal Reasons",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiates",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [510] = "Not Extended",
    [511] = "Network Authentication Required",
}

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

-- From: https://gist.github.com/lunaboards-dev/deea68b29da7b98e0c9222850486ce1e
local function parse_form_data(body, boundry)
    local s, e = body:find(boundry .. "\r\n")
    local t = {}
    local eor_reached = false
    while (not eor_reached and s ~= nil) do
        local ss, se = string.find(body, boundry, e)
        se = se + 2
        if (body:sub(se - 1, se) == "--") then
            eor_reached = true
        end
        --Search for content disposition header
        local cont_disp = body:match("Content%-Disposition:.-\r\n", e - 1):sub(33):gsub("[\r\n]+.+", "")
        local cont_type = body:match("Content%-Type:.-\r\n", e - 1)
        --This tells if we have a file
        if (cont_type ~= nil) then
            cont_type = cont_type:sub(15, -3)
        end
        --Basically just find this and remove it, help the parser out.
        local sm = cont_disp:find(";")
        if (sm ~= nil) then
            cont_disp = cont_disp:sub(1, sm - 1) .. cont_disp:sub(sm + 1)
        end
        --Find the end of Content-Disposition. Could have done this better, in case it sends headers.
        local _, cont_end = body:find("Content%-Disposition:.-\r\n\r\n", e - 1)
        local ct = {}
        --Find a key/value pair
        local cs, ce = cont_disp:find(".-=\".-\"")
        while (cs) do
            --Get our pair.
            local cb = cont_disp:sub(cs, ce)
            --Find the key
            local cd_key = cb:match(".-=\""):sub(1, -3)
            --Find the value
            local cd_value = cb:match("=\".-\""):sub(3, -2)
            --Store
            ct[cd_key] = cd_value
            --Find the next one
            cs, ce = cont_disp:find(".-=\".-\"", ce)
            --But it's not super accurate.
            if (cs ~= nil) then cs = cs + 2 end
        end
        --Do we have a file?
        if (ct.filename ~= nil) then
            --Yes, add it like so
            t[ct.name] = {
                data = body:sub(cont_end + 1, ss - 3),
                headers = ct,
                mime = cont_type
            }
        else
            --No. Just add the data.
            t[ct.name] = body:sub(cont_end + 1, ss - 3);
        end
        s, e = ss, se
    end
    return t
end

local function send_response(response, status)
    local content_type = "text/html"
    if type(response) == "table" then
        content_type = "application/json"
        response = cjson.encode(response)
    end
    if status == nil then
        status = "200 OK"
    else
        assert(STATUS_MESSAGES[status], "HTTP response status code not defined")
        status = status .. " " .. STATUS_MESSAGES[status]
    end
    uhttpd.send("Status: " .. status .. "\r\n")
    uhttpd.send("Content-Type: " .. content_type .. "\r\n\r\n")
    uhttpd.send(response)
end

local function parse_incoming_data(headers, buffer)
    if not headers["content-type"] then
        send_response({ error = "Content type not provided" }, 400)
        os.exit()
    end

    if string.match(headers["content-type"], "^application/json") then
        local status, data = pcall(cjson.decode, buffer)
        if not status then
            send_response({ error = "Invalid json" }, 400)
            os.exit()
        else
            return data
        end
    end

    if string.match(headers["content-type"], "^application/x%-www%-form%-urlencoded") then
        local status, data = pcall(parse_query_string, buffer)
        if not status then
            send_response({ error = "Invalid form data" }, 400)
            os.exit()
        else
            return data
        end
    end

    if string.match(headers["content-type"], "^multipart/form%-data") then
        local boundary = string.match(headers["content-type"], "^multipart/form%-data; boundary=(.+)$")
        if not boundary then
            send_response({ error = "Boundary not found" }, 400)
            os.exit()
        end

        local status, data = pcall(parse_form_data, buffer, boundary)
        if not status then
            send_response({ error = "Invalid form data" }, 400)
            os.exit()
        else
            return data
        end
    end

    if string.match(headers["content-type"], "^text/plain") then
        return buffer
    end

    send_response({ error = "Unable to handle this content type" }, 500)
    os.exit()
end

-- JWT secret key
local JWT_SECRET_KEY = "random_key"
-- Maximum allowed content length
local LARGEST_CONTENT_LENGTH = 1048576

-- Main body required by uhhtpd-lua plugin
function handle_request(env)
    local path = parse_request_uri(env.REQUEST_URI)
    if path == "" then
        return send_response({ error = "Not Found" }, 404)
    end

    local endpoint = prequire("endpoints." .. path)
    if not endpoint then
        return send_response({ error = "Not Found" }, 404)
    end

    env.query = parse_query_string(env.QUERY_STRING)
    env.auth_headers = parse_authorization_header(env.headers)

    local function recv()
        local len = tonumber(env.CONTENT_LENGTH) or 0
        if len > LARGEST_CONTENT_LENGTH then
            send_response({ error = "Content too large" }, 413)
            os.exit()
        end

        local buf = { "" }
        while len > 0 do
            local rlen, rbuf = uhttpd.recv(4096)
            if rlen == 0 then
                break
            end
            len = len - rlen
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
