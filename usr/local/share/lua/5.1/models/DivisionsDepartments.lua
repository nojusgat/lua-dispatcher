local DivisionsDepartments = function (sql, Divisions, Departments)
    return sql:Table({
        name = "divisions_departments",
        columns = {
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
            {
                name = "department_id",
                type = "number",
                nullable = false,
                primary_key = true,
                foreign_key = {
                    table = Departments,
                    delete = "CASCADE"
                }
            },
        }
    })
end

return DivisionsDepartments