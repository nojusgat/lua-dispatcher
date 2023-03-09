local CompaniesOffices = function (sql, Companies, Offices)
    return sql:Table({
        name = "companies_offices",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "company_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Companies,
                    delete = "CASCADE"
                }
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
        }
    })
end

return CompaniesOffices