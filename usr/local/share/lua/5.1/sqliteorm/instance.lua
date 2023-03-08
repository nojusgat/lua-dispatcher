local driver = require "luasql.sqlite3"
local Table = require "sqliteorm.table"
local Column = require "sqliteorm.column"

local SQLiteOrm = {}

function SQLiteOrm:new(database, foreign_keys)
    local instance = setmetatable({}, { __index = SQLiteOrm })
    local sql = assert(driver.sqlite3())
    instance._database = database
    instance._connect = assert(sql:connect(instance._database))
    instance.Table = Table
    instance.Column = Column
    if foreign_keys == true then
        instance:execute("PRAGMA foreign_keys = ON")
    end
    return instance
end

function SQLiteOrm:escape(string)
    return assert(self._connect:escape(string))
end

function SQLiteOrm:execute(query)
    return assert(self._connect:execute(query))
end

function SQLiteOrm:last_id()
    return self._connect:getlastautoid()
end

setmetatable(SQLiteOrm, { __call = SQLiteOrm.new })

return SQLiteOrm
