local hmac = require "openssl.hmac"
local base64 = require "base64"
local cjson = require "cjson"

local base64_encoder = base64.makeencoder("-", "_")
local base64_decoder = base64.makedecoder("-", "_")

local function base64_url_encode(input)
    local result = base64.encode(input, base64_encoder):gsub("=", "")
    return result
end

local function base64_url_decode(input)
    local reminder = #input % 4

    if reminder > 0 then
        local padlen = 4 - reminder
        input = input .. string.rep('=', padlen)
    end

    return base64.decode(input, base64_decoder)
end

local function hmac_encrypt(key, type, data)
    return hmac.new(key, type):final(data)
end

local function table_contains(table, value)
    for _, val in pairs(table) do
        if val == value then
            return true
        end
    end
    return false
end

local algorithms = {
    ["HS256"] = function(key, data)
        return hmac_encrypt(key, "sha256", data)
    end,
    ["HS384"] = function(key, data)
        return hmac_encrypt(key, "sha384", data)
    end,
    ["HS512"] = function(key, data)
        return hmac_encrypt(key, "sha512", data)
    end
}

local JWT = {}

function JWT:new(key, algorithm)
    algorithm = algorithm or "HS256"
    assert(key ~= nil and type(key) == "string", "JWT invalid secret key")
    assert(algorithms[algorithm] ~= nil, "JWT algorithm not supported")

    local instance = setmetatable({}, {
        __index = JWT
    })
    instance._secret = key
    instance._algorithm = algorithms[algorithm]
    instance._header = {
        alg = algorithm,
        typ = "JWT"
    }
    instance._iss = nil
    instance._exp = nil
    instance._nbf = nil
    return instance
end

function JWT:secret(secret)
    local instance = setmetatable({}, {
        __index = self
    })
    instance._secret = secret
    return instance
end

function JWT:require_exp(time)
    local instance = setmetatable({}, {
        __index = self
    })
    if not time then
        instance._exp = os.time
    else
        instance._exp = function()
            return time
        end
    end
    return instance
end

function JWT:require_nbf(time)
    local instance = setmetatable({}, {
        __index = self
    })
    if not time then
        instance._nbf = os.time
    else
        instance._nbf = function()
            return time
        end
    end
    return instance
end

function JWT:require_iss(issuers)
    assert(type(issuers) == "table", "Issuers should be a table")
    local instance = setmetatable({}, {
        __index = self
    })
    instance._iss = issuers
    return instance
end

function JWT:encode(payload)
    if type(payload) ~= "table" then
        return nil, "Payload should be a table"
    end

    local segments = {base64_url_encode(cjson.encode(self._header)), base64_url_encode(cjson.encode(payload))}

    local data = table.concat(segments, ".")

    local signature = self._algorithm(self._secret, data)

    table.insert(segments, base64_url_encode(signature))

    return table.concat(segments, ".")
end

function JWT:decode(token, verify)
    if not verify then
        verify = true
    end
    if not token then
        return nil, "Token should not be empty"
    end
    if type(verify) ~= "boolean" then
        return nil, "Verification should be either true or false"
    end
    if type(token) ~= "string" then
        return nil, "Token should be string"
    end

    local base64_header, base64_payload, base64_secret = string.match(token, "^([^.]+)%.([^.]+)%.([^.]+)$")

    if not base64_header or not base64_payload or not base64_secret then
        return nil, "Invalid token"
    end

    local status, header, payload, secret = pcall(function()
        return cjson.decode(base64_url_decode(base64_header)), cjson.decode(base64_url_decode(base64_payload)),
            base64_url_decode(base64_secret)
    end)

    if status == false then
        return nil, "Invalid token"
    end

    if verify == true then
        if header.alg ~= self._header.alg then
            return nil, "Invalid Algorithm"
        end
        if header.typ ~= self._header.typ then
            return nil, "Invalid Token Type"
        end
        if secret ~= self._algorithm(self._secret, base64_header .. "." .. base64_payload) then
            return nil, "Invalid Token Signature"
        end
        if type(self._exp) == "function" then
            if type(payload.exp) ~= "number" then
                return nil, "Invalid Expiration Time Claim"
            end
            if payload.exp <= self._exp() then
                return nil, "Token expired"
            end
        else
            if payload.exp and type(payload.exp) ~= "number" then
                return nil, "Invalid Expiration Time Claim"
            end
            if payload.exp and payload.exp <= os.time() then
                return nil, "Token expired"
            end
        end
        if type(self._nbf) == "function" then
            if type(payload.nbf) ~= "number" then
                return nil, "Invalid Not Before Claim"
            end
            if payload.nbf > self._nbf() then
                return nil, "Token used before specified time"
            end
        else
            if payload.nbf and type(payload.nbf) ~= "number" then
                return nil, "Invalid Not Before Claim"
            end
            if payload.nbf and payload.nbf > os.time() then
                return nil, "Token used before specified time"
            end
        end
        if type(self._iss) == "table" and not payload.iss then
            return nil, "Issuer is required but not found"
        end
        if type(self._iss) == "table" and table_contains(self._iss, payload.iss) == false then
            return nil, "Invalid Issuer"
        end
    end

    return payload
end

setmetatable(JWT, {
    __call = JWT.new
})

return JWT
