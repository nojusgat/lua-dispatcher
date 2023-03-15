local OfficesDivisions = function (sql, Offices, Divisions)
    return sql:Table({
        name = "offices_divisions",
        columns = {
            {
                name = "office_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Offices,
                    delete = "CASCADE"
                }
            },
            {
                name = "division_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Divisions,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return OfficesDivisions