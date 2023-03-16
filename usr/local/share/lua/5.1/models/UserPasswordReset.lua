local UserPasswordReset = function (sql, Users)
    return sql:Table({
        name = "user_password_reset",
        columns = {
            {
                name = "user_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Users,
                    delete = "CASCADE"
                }
            },
            {
                name = "code",
                type = "number",
                nullable = false,
                unique = true
            },
            {
                name = "expire",
                type = "number",
                nullable = false
            },
        },
    })
end

return UserPasswordReset