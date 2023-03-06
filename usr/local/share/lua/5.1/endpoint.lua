local jwt = require "luajwt"

local Endpoint = {}
Endpoint.__index = Endpoint

local function table_keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

local function table_contains(tbl, x)
    local found = false
    for _, v in pairs(tbl) do
        if v == x then
            found = true
        end
    end
    return found
end

function Endpoint:new(instance)
    instance = instance or {}
    self.enabled_authorization = {}
    self.enabled_cors = {}
    setmetatable(instance, self)
    return instance
end

function Endpoint:enable_cors(method, domains)
    if domains == nil then domains = true end
    assert(type(domains) == "table" or type(domains) == "boolean", "Domains should be a table or a boolean")
    if not method then
        for _, v in pairs(self.http_methods) do
            self.enabled_cors[v:lower()] = domains
        end
        return
    end

    self.enabled_cors[method:lower()] = domains
end

function Endpoint:cors_options(method)
    local cors = self.enabled_cors[method]

    local allowed_methods = self:allowed_methods(table_keys(self.enabled_cors))
    local methods = string.upper(table.concat(allowed_methods, ", "))

    if cors ~= nil then
        if type(cors) == "table" and table_contains(cors, self.env.headers.origin) then
            return {
                origin = self.env.headers.origin,
                methods = methods
            }
        elseif type(cors) == "boolean" and cors == true then
            return {
                origin = "*",
                methods = methods
            }
        end
        return { origin = "" }
    end
    return {}
end

function Endpoint:enable_auth(method)
    if not method then
        for _, v in pairs(self.http_methods) do
            self.enabled_authorization[v:lower()] = true
        end
        return
    end

    self.enabled_authorization[method:lower()] = true
end

function Endpoint:authorized(method)
    if not self.enabled_authorization[method] then
        return true
    end

    if self.env.auth_headers.type ~= "Bearer" then
        return false
    end

    local decoded = jwt.decode(self.env.auth_headers.token, self.jwt_secret_key, true)
    if not decoded then
        return false
    end

    self.auth_data = decoded
    return true
end

function Endpoint:allowed_methods(method_table)
    local methods = {}
    for _, val in pairs(method_table) do
        if self[string.lower(val)] ~= nil then
            table.insert(methods, val)
        end
    end
    return methods
end

function Endpoint:options()
    local cors = {}
    if self.env.headers["access-control-request-method"] then
        cors = self:cors_options(string.lower(self.env.headers["access-control-request-method"]))
    end
    local allowed_methods = self:allowed_methods(self.http_methods)
    local methods = table.concat(allowed_methods, ", ")
    self.send_options(cors, methods)
end

function Endpoint:handle_request()
    local method = string.lower(self.env.REQUEST_METHOD)
    if next(self.enabled_cors) ~= nil then
        self.send = function(response, status)
            self.send_cors(response, status, self:cors_options(method))
        end
    end

    local methods = self:allowed_methods(self.http_methods)
    if not table_contains(methods, string.upper(self.env.REQUEST_METHOD)) then
        return self.send({ error = "Method Not Allowed" }, 405)
    end

    if self:authorized(method) then
        return self[method](self)
    end

    self.send({ error = "Unauthorized" }, 401)
end

return Endpoint
