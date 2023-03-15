local UserPermissions = function (sql, Users)
    return sql:Table({
        name = "user_permissions",
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
                name = "edit_employees",
                type = "boolean",
                nullable = false
            },
            {
                name = "delete_employees",
                type = "boolean",
                nullable = false
            },
            {
                name = "edit_companies",
                type = "boolean",
                nullable = false
            },
            {
                name = "delete_companies",
                type = "boolean",
                nullable = false
            },
            {
                name = "edit_offices",
                type = "boolean",
                nullable = false
            },
            {
                name = "delete_offices",
                type = "boolean",
                nullable = false
            },
            {
                name = "edit_structure",
                type = "boolean",
                nullable = false
            },
            {
                name = "delete_structure",
                type = "boolean",
                nullable = false
            },
            {
                name = "read_permissions",
                type = "boolean",
                nullable = false
            },
            {
                name = "edit_permissions",
                type = "boolean",
                nullable = false
            },
        },
    })
end

return UserPermissions