module(..., package.seeall)

local HTTP_RESP_FORMAT =
"HTTP/1.1 200 OK\r\n".."Content-Length: %d\r\n"..
"Content-Type: application/json\r\n".."Connection: keep-alive\r\n".."\r\n%s"

function FindValueOfKey(para, key)
    local _, _, value = string.find(para, key .. "=(.-)&")
    if not value then
        _, _, value = string.find(para, key.."=(.-)$")
    end
    return value
end

function ErrRet(ret)
	return string.format(HTTP_RESP_FORMAT, string.len(ret), ret)
end

function DoTest1(msg)
	local val = FindValueOfKey(msg.para, "xx")
	print(val)
	local val = FindValueOfKey(msg.para, "yy")
	print(val)
	local val = FindValueOfKey(msg.para, "zz")
	print(val)
	return true
end

function RetTest1()
	local ret = "OK 1.\n"
	return string.format(HTTP_RESP_FORMAT, string.len(ret), ret)
end

function DoTest2(msg)
	return true
end

function RetTest2()
	local ret = "OK 2.\n"
	return string.format(HTTP_RESP_FORMAT, string.len(ret), ret)
end

cmd_handlers = {
	["/test1"] = {
		do_func = DoTest1,
		ret_func = RetTest1,
	},
	["/test2"] = {
		do_func = DoTest2,
		ret_func = RetTest2,
	},
}