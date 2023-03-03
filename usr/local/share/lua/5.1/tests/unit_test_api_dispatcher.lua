local lu = require "luaunit"

package.path = "/www/cgi-bin/?.lua;" .. package.path
package.loaded["cjson"] = require "tests.fake_cjson"

_G._TEST = true
_G.uhttpd = require "tests.fake_uhttpd"
local dispatcher = require "api_dispatcher"

-- Helper function to assert data from uhttpd.send function
local function assertUhttpdSend(status, content_type, response, disposition)
    return function (data)
        if status and string.find(data, "Status: ") then
            lu.assertStrContains(data, status)
        elseif content_type and string.find(data, "Content%-Type: ") then
            lu.assertStrContains(data, content_type)
        elseif disposition and string.find(data, "Content%-Disposition: ") then
            lu.assertStrContains(data, disposition)
        elseif response then
            lu.assertStrContains(data, response)
        end
    end
end

-- Workaround for testing function that has os.exit inside it
local function ignoreOsExit(...)
    local status, err = pcall(...)
    lu.assertIsFalse(status)
    lu.assertStrContains(err, "You are trying to exit but there is still a running instance of LuaUnit.")
    return status, err
end

TestParsers = {}
    function TestParsers:test_TrailingSlash_ReturnsWithoutTrailingSlash()
        lu.assertEquals(
            dispatcher.remove_last_slash("/api/"),
            "/api"
        )
        lu.assertEquals(
            dispatcher.remove_last_slash("/api////"),
            "/api"
        )
        lu.assertEquals(
            dispatcher.remove_last_slash("/api/example//"),
            "/api/example"
        )
    end

    function TestParsers:test_RequestUri_HasSpaces_ReturnsWithUnderscores()
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/hello world/"),
            "hello_world"
        )
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/hello  world"),
            "hello_world"
        )
    end

    function TestParsers:test_RequestUri_HasQuery_ReturnsWithoutQuery()
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/hello/world/?example=test"),
            "hello.world"
        )
        lu.assertEquals(
            dispatcher.parse_request_uri("/api///example/?example=test/"),
            "example"
        )
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/example?example=test"),
            "example"
        )
    end

    function TestParsers:test_RequestUri_ReturnsParsedString()
        lu.assertEquals(
            dispatcher.parse_request_uri("/api///example///"),
            "example"
        )
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/hello world"),
            "hello_world"
        )
        lu.assertEquals(
            dispatcher.parse_request_uri("/api/hello/world/"),
            "hello.world"
        )
    end

    function TestParsers:test_QueryString_HasMultiple_ReturnsParsedTable()
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example=test&test=example"),
            { example = "test", test = "example" }
        )
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example=test&&test=example&&"),
            { example = "test", test = "example" }
        )
    end

    function TestParsers:test_QueryString_HasSpaces_ReturnsWithUnderscores()
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example test=te st"),
            { example_test = "te st" }
        )
    end

    function TestParsers:test_QueryString_HasNoValue_ReturnsWithoutValue()
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example=&test="),
            { example = "", test = "" }
        )
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example&test"),
            { example = "", test = "" }
        )
    end

    function TestParsers:test_QueryString_ReturnsParsedTable()
        lu.assertItemsEquals(
            dispatcher.parse_query_string("example=test"),
            { example = "test" }
        )
    end

    function TestParsers:test_AuthorizationHeader_HasEmptyHeader_ReturnsEmptyTable()
        lu.assertItemsEquals(
            dispatcher.parse_authorization_header({}),
            {}
        )
        lu.assertItemsEquals(
            dispatcher.parse_authorization_header({
                authorization = ""
            }),
            {}
        )
    end

    function TestParsers:test_AuthorizationHeader_HasIncompleteHeader_ReturnsEmptyTable()
        lu.assertItemsEquals(
            dispatcher.parse_authorization_header({
                authorization = "Basic "
            }),
            {}
        )
    end

    function TestParsers:test_AuthorizationHeader_ReturnsParsedTable()
        lu.assertItemsEquals(
            dispatcher.parse_authorization_header({
                authorization = "Basic token"
            }),
            { type = "Basic", token = "token" }
        )
        lu.assertItemsEquals(
            dispatcher.parse_authorization_header({
                authorization = "Basic token 123 123"
            }),
            { type = "Basic", token = "token" }
        )
    end
-- end of table TestParsers

local original_uhttpd_send = _G.uhttpd.send
local original_uhttpd_recv = _G.uhttpd.recv
local original_require = require
TestHandling = {}
    function TestHandling:tearDown()
        _G.uhttpd.send = original_uhttpd_send
        _G.uhttpd.recv = original_uhttpd_recv
        require = original_require
    end

    function TestHandling:test_SendResponse_HasInvalidHTTPCode_ThrowsError()
        lu.assertErrorMsgContains("HTTP response status code not defined", function ()
            dispatcher.send_response("", "invalid")
        end)
    end

    function TestHandling:test_SendResponse_HasValidHTTPCode_ReturnsResponse()
        _G.uhttpd.send = assertUhttpdSend("500 Internal Server Error")
        dispatcher.send_response("", 500)
    end

    function TestHandling:test_SendResponse_HasTable_ReturnsJson()
        _G.uhttpd.send = assertUhttpdSend("200 OK", "application/json", "fake_cjson_encode")
        dispatcher.send_response({ hello = "world" })
    end

    function TestHandling:test_SendResponse_HasString_ReturnsHtml()
        _G.uhttpd.send = assertUhttpdSend("200 OK", "text/html", "hello world")
        dispatcher.send_response("hello world")
    end

    function TestHandling:test_SendFile_HasNoExtension_ReturnsGenericContentType()
        local file_name = "test.unknown"
        _G.uhttpd.send = assertUhttpdSend("200 OK", "application/octet-stream", "", file_name)
        dispatcher.send_file("", file_name)
    end

    function TestHandling:test_SendFile_HasExtension_ReturnsCorrectContentType()
        local file_name = "test.png"
        _G.uhttpd.send = assertUhttpdSend("200 OK", "image/png", "", file_name)
        dispatcher.send_file("", file_name)
    end

    function TestHandling:test_SendFile_HasNoFilename_ReturnsDefaultFilename()
        _G.uhttpd.send = assertUhttpdSend("200 OK", "application/octet-stream", "", "file")
        dispatcher.send_file("")
    end

    function TestHandling:test_BodyParser_HasNoContentType_ReturnsBadRequestError()
        _G.uhttpd.send = assertUhttpdSend("400 Bad Request")
        ignoreOsExit(dispatcher.parse_incoming_data, {}, "")
    end

    function TestHandling:test_BodyParser_HasUnknownContentType_ReturnsBadRequestError()
        _G.uhttpd.send = assertUhttpdSend("500 Internal Server Error")
        ignoreOsExit(dispatcher.parse_incoming_data, {
            ["content-type"] = "test"
        }, "")
    end

    function TestHandling:test_BodyParser_HasJson_ReturnsTable()
        local data = dispatcher.parse_incoming_data({
            ["content-type"] = "application/json"
        }, '{"json": "data"}')
        lu.assertEquals(data, "fake_cjson_decode")
    end

    function TestHandling:test_BodyParser_HasFormUrlEncode_ReturnsTable()
        local data = dispatcher.parse_incoming_data({
            ["content-type"] = "application/x-www-form-urlencoded"
        }, "hello=world")
        lu.assertItemsEquals(data, { hello = "world" })
    end

    function TestHandling:test_BodyParser_HasMultipartFormDataWithoutBoundary_ReturnsBadRequestError()
        _G.uhttpd.send = assertUhttpdSend("400 Bad Request")
        ignoreOsExit(dispatcher.parse_incoming_data, {
            ["content-type"] = "multipart/form-data"
        }, '------boundry\r\nContent-Disposition: form-data; name="hello"\r\n\r\nworld\r\n------boundry--')
    end

    function TestHandling:test_BodyParser_HasMultipartFormDataInvalidBoundary_ReturnsBadRequestError()
        _G.uhttpd.send = assertUhttpdSend("400 Bad Request")
        ignoreOsExit(dispatcher.parse_incoming_data, {
            ["content-type"] = "multipart/form-data; boundary=----WebKitFormBoundaryte0b0me8CAGLhtzJ"
        }, '------boundry\r\nContent-Disposition: form-data; name="hello"\r\n\r\nworld\r\n------boundry--')
    end

    function TestHandling:test_BodyParser_HasMultipartFormDataInvalidData_ReturnsBadRequestError()
        _G.uhttpd.send = assertUhttpdSend("400 Bad Request")
        ignoreOsExit(dispatcher.parse_incoming_data, {
            ["content-type"] = "multipart/form-data; boundary=----boundry"
        }, '------boundry\r\nname="hello"\r\n\r\nworld\r\n------boundry--')
    end

    function TestHandling:test_BodyParser_HasMultipartFormData_ReturnsTable()
        local data = dispatcher.parse_incoming_data({
            ["content-type"] = "multipart/form-data; boundary=----boundry"
        }, '------boundry\r\nContent-Disposition: form-data; name="hello"\r\n\r\nworld\r\n------boundry--')
        lu.assertItemsEquals(data, { hello = "world" })
    end

    function TestHandling:test_BodyParser_HasPlainText_ReturnsString()
        local data = dispatcher.parse_incoming_data({
            ["content-type"] = "text/plain"
        }, "hello world")
        lu.assertEquals(data, "hello world")
    end

    function TestHandling:test_HandleRequest_HasNoEndpoint_ReturnsNotFoundError()
        require = function ()
            return nil
        end
        _G.uhttpd.send = assertUhttpdSend("404 Not Found")
        dispatcher.handle_request({ REQUEST_URI = "/api/hello" })
    end

    function TestHandling:test_HandleRequest_HasBodyTooLargeContentLength_ReturnsContentTooLargeError()
        -- Mock endpoint
        require = function ()
            return {
                new = function (_, instance)
                    return {
                        handle_request = function ()
                            ignoreOsExit(instance.body)
                        end
                    }
                end,
            }
        end
        _G.uhttpd.send = assertUhttpdSend("413 Content Too Large")
        dispatcher.handle_request({ REQUEST_URI = "/api/hello", CONTENT_LENGTH = math.huge })
    end

    function TestHandling:test_HandleRequest_HasBodyNoContentLength_ReturnsNoBody()
        -- Mock endpoint
        require = function ()
            return {
                new = function (_, instance)
                    return {
                        handle_request = function ()
                            local data = instance.body()
                            lu.assertEquals(data, nil)
                            lu.success()
                        end
                    }
                end,
            }
        end
        dispatcher.handle_request({ REQUEST_URI = "/api/hello" })
        lu.fail("Failed to call handle_request")
    end

    function TestHandling:test_HandleRequest_HasBodyContentLengthLargerThanBody_ReturnsNoBody()
        _G.uhttpd.recv = function ()
            return 0, nil
        end
        -- Mock endpoint
        require = function ()
            return {
                new = function (_, instance)
                    return {
                        handle_request = function ()
                            local data = instance.body()
                            lu.assertEquals(data, nil)
                            lu.success()
                        end
                    }
                end,
            }
        end
        dispatcher.handle_request({ REQUEST_URI = "/api/hello", CONTENT_LENGTH = 1000 })
        lu.fail("Failed to call handle_request")
    end

    function TestHandling:test_HandleRequest_ReturnsLoadedEndpoint()
        -- Mock endpoint
        require = function (module)
            lu.assertEquals(module, "endpoints.hello")
            return {
                new = function ()
                    return {
                        handle_request = function ()
                            lu.success()
                        end
                    }
                end,
            }
        end
        dispatcher.handle_request({ REQUEST_URI = "/api/hello" })
        lu.fail("Failed to load endpoint")
    end
-- end of table TestHandling

os.exit(lu.LuaUnit.run())