package.loaded["uci"] = {
    cursor = function () return {} end
}

local lu = require "luaunit"
local uciorm = require "uciorm"

TestUciWithoutSection = {}
    function TestUciWithoutSection:setUp()
        self.uciorm = uciorm:init("example")
    end

    function TestUciWithoutSection:test_CreateSection_HasNoType_ReturnsFalse()
        self.uciorm.uci = {
            add = function () return "example" end
        }
        local is_created = self.uciorm:create()
        lu.assertIsFalse(is_created)
    end

    function TestUciWithoutSection:test_CreateSection_HasType_ReturnsTrue()
        self.uciorm.uci = {
            add = function () return "example" end
        }
        local is_created = self.uciorm:create("example")
        lu.assertIsTrue(is_created)
    end

    function TestUciWithoutSection:test_GetOption_HasNoSection_ReturnsError()
        lu.assertErrorMsgContains("Section is not defined", function ()
            local _ = self.uciorm.options.example
        end)
    end

    function TestUciWithoutSection:test_SetOption_HasNoSection_ReturnsError()
        lu.assertErrorMsgContains("Section is not defined", function ()
            self.uciorm.options.example = "test"
        end)
    end

    function TestUciWithoutSection:test_DeleteOption_HasNoSection_ReturnsError()
        lu.assertErrorMsgContains("Section is not defined", function ()
            self.uciorm.options.example = nil
        end)
    end

    function TestUciWithoutSection:test_GetAllOptions_HasNoSection_ReturnsError()
        lu.assertErrorMsgContains("Section is not defined", function ()
            local _ = self.uciorm.options()
        end)
    end
-- end of table TestUciWithoutSection

TestUciWithSection = {}
    function TestUciWithSection:setUp()
        self.uciorm = uciorm:init("example", "section")
    end

    function TestUciWithSection:test_CreateSection_SectionDoesNotExist_ReturnsTrue()
        self.uciorm.uci = {
            get_all = function () return nil end,
            set = function () end
        }
        local is_created = self.uciorm:create("example")
        lu.assertIsTrue(is_created)
    end

    function TestUciWithSection:test_CreateSection_SectionExists_ReturnsFalse()
        self.uciorm.uci = {
            get_all = function (...) return {...} end
        }
        local is_created = self.uciorm:create("example")
        lu.assertIsFalse(is_created)
    end

    function TestUciWithSection:test_GetOption_HasSection_ReturnsOption()
        self.uciorm.uci = {
            get = function () return "test" end
        }
        self.uciorm:update_metatable()

        local option = self.uciorm.options.example
        lu.assertEquals(option, "test")
    end

    function TestUciWithSection:test_SetOption_HasSection_SetsOption()
        self.uciorm.uci = {
            set = function (_, _config, _section, _option, _value)
                lu.assertEquals(_option, "example")
                lu.assertEquals(_value, "test")
                lu.success()
            end
        }
        self.uciorm:update_metatable()

        self.uciorm.options.example = "test"
        lu.fail("Failed to set option")
    end

    function TestUciWithSection:test_DeleteOption_HasSection_DeletesOption()
        self.uciorm.uci = {
            delete = function (_, _config, _section, _option)
                lu.assertEquals(_option, "example")
                lu.success()
            end
        }
        self.uciorm:update_metatable()

        self.uciorm.options.example = nil
        lu.fail("Failed to delete option")
    end

    function TestUciWithSection:test_GetAllOptions_HasSection_ReturnsAllOptions()
        self.uciorm.uci = {
            get_all = function () return "options" end
        }
        self.uciorm:update_metatable()

        local options = self.uciorm.options()
        lu.assertEquals(options, "options")
    end
-- end of table TestUciWithSection

os.exit(lu.LuaUnit.run())