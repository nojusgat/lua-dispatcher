local Departments = function (sql)
    return sql:Table({
        name = "departments",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "name",
                type = "string",
                nullable = false
            },
        }
    })
end

return Departments