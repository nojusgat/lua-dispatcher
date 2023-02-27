local endpoint = {}

-- Define all endpoints
endpoint["endpoints"] = {
    require("endpoints.test"),
    require("endpoints.hello")
}

local function remove_last_slash(uri)
    if string.sub(uri, -1) == "/" then
        return remove_last_slash(string.sub(uri, 1, -2))
    end
    return uri
end

function endpoint:parse_request_uri()
    local request_uri = remove_last_slash(self.env.REQUEST_URI)
    local parameters_start = string.find(request_uri, "?")
    if parameters_start ~= nil then
        request_uri = remove_last_slash(string.sub(request_uri, 1, parameters_start - 1))
    end
    request_uri = string.gsub(request_uri, "/+api/+", "")
    return request_uri
end

function endpoint:parse_query_string()
    local values = {}
    for key, val in string.gmatch(self.env.QUERY_STRING, "([^&=]+)(=*[^&=]*)") do
		local d_key = self.decode(key)
        local d_val = self.decode(val)
		d_key = d_key:gsub('=+.*$', "")
		d_key = d_key:gsub('%s', "_")
		d_val = d_val:gsub('^=+', "")

        values[d_key] = d_val
	end
    return values
end

function endpoint:handle_request()
    local request_uri = self:parse_request_uri()
    local query_string = self:parse_query_string()
    for _, v in pairs(self.endpoints) do
        if v.path == request_uri then
            v.handle(self.send, query_string)
            return
        end
    end
    self.send("Not Found", 404)
end

return endpoint
