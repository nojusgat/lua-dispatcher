local sqlite = require "sqliteorm.instance"

local sql = sqlite("data.db", true)

local HelloEndpoint = {}
HelloEndpoint.__index = HelloEndpoint

setmetatable(HelloEndpoint, { __index = Endpoint })

function HelloEndpoint:init()
    -- Enables cors for all methods, specified domains
    self:enable_cors(nil, { "https://www.google.com", "https://stackoverflow.com" })
end

function HelloEndpoint:get()
    local Test = sql:Table({
        name = "test",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "text",
                type = "string"
            },
        }
    })

    local Users = sql:Table({
        name = "users",
        columns = {
            {
                name = "id",
                type = "number",
                primary_key = true,
                auto_increment = true
            },
            {
                name = "text",
                type = "string"
            },
            {
                name = "test_id",
                type = "number",
                nullable = false,
                foreign_key = {
                    table = Test
                }
            },
        }
    })

    local create_test_row = Test({
        text = "123",
    })
    create_test_row:save()

    local first_user = Users:get():left_join(Test):find_one()

    self.send({ text = "Hello World", query = self.env.query, test = first_user.test.text })
end

-- function HelloEndpoint:get()
--     self.send({ text = "Hello World", query = self.env.query })
-- end

function HelloEndpoint:post()
    local data = self.body()
    self.send({ text = "Hello World", data = data })
end

return HelloEndpoint
