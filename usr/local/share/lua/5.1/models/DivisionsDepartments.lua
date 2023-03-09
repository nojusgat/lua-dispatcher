local DivisionsDepartments = function (sql, Divisions, Departments)
    return sql:Table({
        name = "divisions_departments",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
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
            {
                name = "department_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Departments,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return DivisionsDepartments