local Users = function (sql, UserPermissions)
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
                name = "name",
                type = "string"
            },
            {
                name = "email",
                type = "string"
            },
            {
                name = "password",
                type = "string"
            },
            {
                name = "avatar_path",
                type = "string"
            },
            {
                name = "permissions_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = UserPermissions,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return Users