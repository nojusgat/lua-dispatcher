local Groups = function (sql)
    return sql:Table({
        name = "groups",
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
                nullable = false,
                unique = true
            },
        }
    })
end

return Groups