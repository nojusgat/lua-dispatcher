local jwt = {}

function jwt:new()
    local instance = setmetatable({}, { __index = jwt })
    return instance
end

function jwt:decode(token)
    if token == "valid" then
        return { data_inside_token = "example" }
    end
    return nil
end

setmetatable(jwt, { __call = jwt.new })
return jwt