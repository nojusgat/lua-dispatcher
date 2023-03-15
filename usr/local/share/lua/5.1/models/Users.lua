local Users = function (sql)
    return sql:Table({
        name = "users",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "username",
                type = "string",
                nullable = false,
                unique = true
            },
            {
                name = "name",
                type = "string"
            },
            {
                name = "email",
                type = "string",
                nullable = false,
                unique = true
            },
            {
                name = "password",
                type = "string",
                nullable = false,
            },
            {
                name = "password_salt",
                type = "string",
                nullable = false,
            },
            {
                name = "system_admin",
                type = "boolean",
                nullable = false,
                default = false
            },
            {
                name = "avatar",
                type = "string"
            },
            {
                name = "exp",
                type = "string",
            },
        }
    })
end

return Users