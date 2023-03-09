local Divisions = function (sql)
    return sql:Table({
        name = "divisions",
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

return Divisions