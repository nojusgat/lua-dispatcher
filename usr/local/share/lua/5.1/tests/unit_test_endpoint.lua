package.loaded["luajwt"] = require "tests.fake_luajwt"

local lu = require "luaunit"
local endpoint = require "endpoint"

TestAuth = {}
    function TestAuth:setUp()
        self.endpoint = endpoint:new({
            env = {
                auth_headers = {}
            }
        })
    end

    function TestAuth:test_AllMethods_AuthDisabled_ReturnsAuthorized()
        lu.assertIsTrue(self.endpoint:authorized("post"))
        lu.assertIsTrue(self.endpoint:authorized("put"))
        lu.assertIsTrue(self.endpoint:authorized("get"))
        lu.assertIsTrue(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_AllMethods_AuthEnabled_ReturnsNotAuthorized()
        TestAuth:test_AllMethods_AuthDisabled_ReturnsAuthorized()

        self.endpoint:enable_auth()

        lu.assertIsFalse(self.endpoint:authorized("post"))
        lu.assertIsFalse(self.endpoint:authorized("put"))
        lu.assertIsFalse(self.endpoint:authorized("get"))
        lu.assertIsFalse(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_AllMethodsIndividually_AuthEnabled_ReturnsNotAuthorized()
        TestAuth:test_AllMethods_AuthDisabled_ReturnsAuthorized()

        self.endpoint:enable_auth("post")
        self.endpoint:enable_auth("put")
        self.endpoint:enable_auth("get")
        self.endpoint:enable_auth("delete")

        lu.assertIsFalse(self.endpoint:authorized("post"))
        lu.assertIsFalse(self.endpoint:authorized("put"))
        lu.assertIsFalse(self.endpoint:authorized("get"))
        lu.assertIsFalse(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_PostMethod_AuthEnabled_ReturnsNotAuthorized()
        lu.assertIsTrue(self.endpoint:authorized("post"))

        self.endpoint:enable_auth("post")

        lu.assertIsFalse(self.endpoint:authorized("post"))
        lu.assertIsTrue(self.endpoint:authorized("put"))
        lu.assertIsTrue(self.endpoint:authorized("get"))
        lu.assertIsTrue(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_PutMethod_AuthEnabled_ReturnsNotAuthorized()
        lu.assertIsTrue(self.endpoint:authorized("put"))

        self.endpoint:enable_auth("put")

        lu.assertIsTrue(self.endpoint:authorized("post"))
        lu.assertIsFalse(self.endpoint:authorized("put"))
        lu.assertIsTrue(self.endpoint:authorized("get"))
        lu.assertIsTrue(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_GetMethod_AuthEnabled_ReturnsNotAuthorized()
        lu.assertIsTrue(self.endpoint:authorized("get"))

        self.endpoint:enable_auth("get")

        lu.assertIsTrue(self.endpoint:authorized("post"))
        lu.assertIsTrue(self.endpoint:authorized("put"))
        lu.assertIsFalse(self.endpoint:authorized("get"))
        lu.assertIsTrue(self.endpoint:authorized("delete"))
    end

    function TestAuth:test_DeleteMethod_AuthEnabled_ReturnsNotAuthorized()
        lu.assertIsTrue(self.endpoint:authorized("delete"))

        self.endpoint:enable_auth("delete")

        lu.assertIsTrue(self.endpoint:authorized("post"))
        lu.assertIsTrue(self.endpoint:authorized("put"))
        lu.assertIsTrue(self.endpoint:authorized("get"))
        lu.assertIsFalse(self.endpoint:authorized("delete"))
    end
-- end of table TestAuth

TestHandleRequest = {}
    function TestHandleRequest:setUp()
        self.endpoint = endpoint:new({
            env = {
                auth_headers = {}
            }
        })
    end

    -- Test if endpoint responds with '401 Unauthorized' error
    -- when authentication on requested method is enabled
    -- and no authentication variables are set
    function TestHandleRequest:test_RequestMethod_AuthEnabled_ReturnsUnauthorized()
        self.endpoint.env.REQUEST_METHOD = "POST"
        self.endpoint.send = function (_, err_code)
            lu.assertEquals(err_code, 401)
        end
        self.endpoint.post = function ()
            lu.fail("Post method executed")
        end

        self.endpoint:enable_auth("post")
        self.endpoint:handle_request()
    end

    -- Test if endpoint responds with '401 Unauthorized' error
    -- when authentication on requested method is enabled
    -- and invalid authentication variables are set
    function TestHandleRequest:test_RequestMethod_AuthEnabledInvalidAuth_ReturnsUnauthorized()
        self.endpoint.env.REQUEST_METHOD = "POST"

        self.endpoint.env.auth_headers.type = "example"
        self.endpoint.env.auth_headers.token = "example"

        self.endpoint.send = function (_, err_code)
            lu.assertEquals(err_code, 401)
        end
        self.endpoint.post = function ()
            lu.fail("Post method executed")
        end

        self.endpoint:enable_auth("post")
        self.endpoint:handle_request()
    end

    -- Test if endpoint gets JWT token data when
    -- authentication on requested method is enabled
    -- and the user is authenticated
    function TestHandleRequest:test_Method_AuthEnabledValidAuth_ReturnsAuthData()
        self.endpoint.env.REQUEST_METHOD = "GET"

        self.endpoint.env.auth_headers.type = "Bearer"
        self.endpoint.env.auth_headers.token = "valid"

        self.endpoint.send = function (_, err_code)
            lu.fail("Error " .. err_code)
        end

        self.endpoint.get = function (_self)
            lu.assertEquals(_self.auth_data.data_inside_token, "example")
        end

        self.endpoint:enable_auth("get")
        self.endpoint:handle_request()
    end

    -- Test if endpoint responds with '405 Method Not Allowed' error
    -- when requesting method that is not defined in the endpoint
    function TestHandleRequest:test_Method_Undefined_ReturnsMethodNotAllowed()
        self.endpoint.env.REQUEST_METHOD = "GET"
        self.endpoint.send = function (_, err_code)
            lu.assertEquals(err_code, 405)
        end

        self.endpoint:handle_request()
    end

    -- Test if endpoint responds to the requested
    -- method if the requested method is defined
    function TestHandleRequest:test_Method_Defined_ReturnsSuccess()
        self.endpoint.env.REQUEST_METHOD = "GET"
        self.endpoint.send = function (_, err_code)
            lu.fail("Error " .. err_code)
        end
        self.endpoint.get = function ()
            lu.success()
        end

        self.endpoint:handle_request()
    end
-- end of table TestHandleRequest

os.exit(lu.LuaUnit.run())