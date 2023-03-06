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

local MIME_TYPES = {
    ["aac"] = "audio/aac",
    ["abw"] = "application/x-abiword",
    ["arc"] = "application/x-freearc",
    ["avif"] = "image/avif",
    ["avi"] = "video/x-msvideo",
    ["azw"] = "application/vnd.amazon.ebook",
    ["bmp"] = "image/bmp",
    ["bz"] = "application/x-bzip",
    ["bz2"] = "application/x-bzip2",
    ["cda"] = "application/x-cdf",
    ["csh"] = "application/x-csh",
    ["css"] = "text/css",
    ["csv"] = "text/csv",
    ["doc"] = "application/msword",
    ["docx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ["eot"] = "application/vnd.ms-fontobject",
    ["epub"] = "application/epub+zip",
    ["gz"] = "application/gzip",
    ["gif"] = "image/gif",
    ["html"] = "text/html",
    ["htm"] = "text/html",
    ["ico"] = "image/vnd.microsoft.icon",
    ["ics"] = "text/calendar",
    ["jar"] = "application/java-archive",
    ["jpeg"] = "image/jpeg",
    ["jpg"] = "image/jpeg",
    ["js"] = "text/javascript",
    ["json"] = "application/json",
    ["jsonld"] = "application/ld+json",
    ["mjs"] = "text/javascript",
    ["mp3"] = "audio/mpeg",
    ["mp4"] = "video/mp4",
    ["mpeg"] = "video/mpeg",
    ["mpkg"] = "application/vnd.apple.installer+xml",
    ["odp"] = "application/vnd.oasis.opendocument.presentation",
    ["ods"] = "application/vnd.oasis.opendocument.spreadsheet",
    ["odt"] = "application/vnd.oasis.opendocument.text",
    ["oga"] = "audio/ogg",
    ["ogv"] = "video/ogg",
    ["ogx"] = "application/ogg",
    ["opus"] = "audio/opus",
    ["otf"] = "font/otf",
    ["png"] = "image/png",
    ["pdf"] = "application/pdf",
    ["php"] = "application/x-httpd-php",
    ["ppt"] = "application/vnd.ms-powerpoint",
    ["pptx"] = "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ["rar"] = "application/vnd.rar",
    ["rtf"] = "application/rtf",
    ["sh"] = "application/x-sh",
    ["svg"] = "image/svg+xml",
    ["tar"] = "application/x-tar",
    ["tif"] = "image/tiff",
    ["tiff"] = "image/tiff",
    ["ts"] = "video/mp2t",
    ["ttf"] = "font/ttf",
    ["txt"] = "text/plain",
    ["vsd"] = "application/vnd.visio",
    ["wav"] = "audio/wav",
    ["weba"] = "audio/webm",
    ["webm"] = "video/webm",
    ["webp"] = "image/webp",
    ["woff"] = "font/woff",
    ["woff2"] = "font/woff2",
    ["xhtml"] = "application/xhtml+xml",
    ["xls"] = "application/vnd.ms-excel",
    ["xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ["xml"] = "application/xml",
    ["xul"] = "application/vnd.mozilla.xul+xml",
    ["zip"] = "application/zip",
    ["7z"] = "application/x-7z-compressed",
}

local HTTP_METHODS = {
    "CONNECT",
    "DELETE",
    "GET",
    "HEAD",
    "PATCH",
    "OPTIONS",
    "POST",
    "PUT",
    "TRACE"
}

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
    if not query then
        return values
    end
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
    if not headers then
        return auth
    end
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
    assert(s ~= nil, "Boundry not found")
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
                filename = ct.filename,
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

local function parse_send_response_arguments(response, status)
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

    return content_type, status, response
end

local function set_cors_headers(cors)
    if cors == nil then return end
    assert(type(cors) == "table", "Invalid cors settings")
    local origin = cors.origin
    local methods = cors.methods
    if origin ~= nil then
        if origin ~= "" then
            uhttpd.send("Access-Control-Allow-Origin: " .. origin .. "\r\n")
            if methods ~= nil then
                uhttpd.send("Access-Control-Allow-Methods: " .. methods .. "\r\n")
            end
        end
        if origin ~= "*" then
            uhttpd.send("Vary: Origin\r\n")
        end
    end
end

local function send_response(initial_response, initial_status)
    local content_type, status, response = parse_send_response_arguments(initial_response, initial_status)
    uhttpd.send("Status: " .. status .. "\r\n")
    uhttpd.send("Content-Type: " .. content_type .. "\r\n\r\n")
    uhttpd.send(response)
end

local function send_response_options(cors, allowed_methods)
    uhttpd.send("Status: 200 OK\r\n")
    set_cors_headers(cors)
    if allowed_methods then
        uhttpd.send("Allow: " .. allowed_methods .. "\r\n")
    end
    uhttpd.send("Content-Length: 0\r\n\r\n")
end

local function send_response_file(file_contents, file_name)
    if not file_name then file_name = "file" end
    local content_type = "application/octet-stream"
    local ext = string.match(file_name, "[^%.]+$")
    if ext and MIME_TYPES[string.lower(ext)] then
        content_type = MIME_TYPES[string.lower(ext)]
    end
    uhttpd.send("Status: 200 OK\r\n")
    uhttpd.send("Content-Type: " .. content_type .. "\r\n")
    uhttpd.send("Content-Disposition: attachment; filename=\"" .. file_name .. "\"\r\n\r\n")
    uhttpd.send(file_contents)
end

local function send_response_cors(initial_response, initial_status, cors)
    local content_type, status, response = parse_send_response_arguments(initial_response, initial_status)
    uhttpd.send("Status: " .. status .. "\r\n")
    set_cors_headers(cors)
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
        local receive_bytes = 4096
        while len > 0 do
            local rlen, rbuf = uhttpd.recv(receive_bytes)
            len = len - rlen
            table.insert(buf, rbuf)
            if rlen < receive_bytes or rlen <= 0 then break end
        end
        buf = table.concat(buf)

        if string.len(buf) > 0 then
            return parse_incoming_data(env.headers, buf)
        end

        return nil
    end

    local instance = endpoint:new({
        body = recv,
        send = send_response,
        send_file = send_response_file,
        send_cors = send_response_cors,
        send_options = send_response_options,
        env = env,
        jwt_secret_key = JWT_SECRET_KEY,
        http_methods = HTTP_METHODS
    })
    if instance.init then
        instance:init()
    end
    instance:handle_request()
end

if _TEST then
    local M = {}

    M.prequire = prequire
    M.remove_last_slash = remove_last_slash
    M.parse_request_uri = parse_request_uri
    M.parse_query_string = parse_query_string
    M.parse_authorization_header = parse_authorization_header
    M.parse_form_data = parse_form_data
    M.send_response = send_response
    M.send_file = send_response_file
    M.parse_incoming_data = parse_incoming_data
    M.handle_request = handle_request

    return M
end
