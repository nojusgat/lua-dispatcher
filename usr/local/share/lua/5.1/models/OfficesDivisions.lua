local OfficesDivisions = function (sql, Offices, Divisions)
    return sql:Table({
        name = "offices_divisions",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "office_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Offices,
                    delete = "CASCADE"
                }
            },
            {
                name = "division_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Divisions,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return OfficesDivisions