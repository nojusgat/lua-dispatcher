local CompaniesOffices = function (sql, Companies, Offices)
    return sql:Table({
        name = "companies_offices",
        columns = {
            {
                name = "company_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Companies,
                    delete = "CASCADE"
                }
            },
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
        }
    })
end

return CompaniesOffices