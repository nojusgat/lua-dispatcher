local Offices = function (sql)
    return sql:Table({
        name = "offices",
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
                name = "street",
                type = "string",
                nullable = false
            },
            {
                name = "city",
                type = "string",
                nullable = false
            },
            {
                name = "country",
                type = "string",
                nullable = false
            },
        }
    })
end

return Offices