local uci = require "uci"

local UCIOrm = {}
UCIOrm.__index = UCIOrm

function UCIOrm:init(config, section)
    local instance = {}
    self.uci = uci.cursor()
    self.config = config
    self.section = section
    setmetatable(instance, self)
    self:update_metatable()
    return instance
end

function UCIOrm:create(type)
    if not self.section then
        self.section = self.uci:add(self.config, type)
        self:update_metatable()
        return true
    end
    if not self:get_all() then
        self.uci:set(self.config, self.section, type)
        return true
    end
    return false
end

function UCIOrm:get(option)
    if not self.config or not self.section then
        return nil
    end
    return self.uci:get(self.config, self.section, option)
end

function UCIOrm:get_all()
    if not self.config or not self.section then
        return nil
    end
    return self.uci:get_all(self.config, self.section)
end

function UCIOrm:set(option, value)
    if not self.config or not self.section then
        return
    end
    self.uci:set(self.config, self.section, option, value)
end

function UCIOrm:delete_section()
    if not self.config or not self.section then
        return
    end
    self.uci:delete(self.config, self.section)
end

function UCIOrm:delete_option(option)
    if not self.config or not self.section then
        return
    end
    self.uci:delete(self.config, self.section, option)
end

function UCIOrm:save()
    if not self.config then
        return
    end
    self.uci:commit(self.config)
end

function UCIOrm:update_metatable()
    self.options = setmetatable({}, {
        __index = function(_, key)
            return self:get(key)
        end,
        __newindex = function(_, key, value)
            if value == nil then
                self:delete_option(key)
            else
                self:set(key, value)
            end
        end,
        __call = function()
            return self:get_all()
        end
    })
end

return UCIOrm
