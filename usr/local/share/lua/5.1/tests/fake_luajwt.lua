local jwt = {}

function jwt.decode(token)
    if token == "valid" then
        return { data_inside_token = "example" }
    end
    return nil
end

return jwt