local Companies = function (sql)
    return sql:Table({
        name = "companies",
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

return Companies