local cmd = require "http_svr_cmd"
local socket = require "socket"

local host = "127.0.0.1"
local port = "80"
local server  = assert(socket.bind(host, port, 128))

server:settimeout(0)

local function UrlEncode(s)  
     s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
    return string.gsub(s, " ", "+")  
end
  
local function UrlDecode(s)  
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)  
    return s  
end

local function IsGet(msg)
	local i, j = string.find(msg, "GET")
	if i and i == 1 then
		return true
	else
		return false
	end
end

local function IsPost(msg)
	local i, j = string.find(msg, "POST")
	if i and i == 1 then
		return true
	else
		return false
	end
end

local function RecvHttpMsg(client)
	local msg, err = client:receive()
	if err then return { err_msg = err, } end

	if IsGet(msg) then
		-- skip "GET "
		local msg = string.sub(msg, 5)
		-- find url
		local i, j = string.find(msg, "?")
		local url = string.sub(msg, 1, i - 1)
		-- find para
		local x, y = string.find(msg, " ")
		local para = string.sub(msg, i + 1, x - 1)

		return {
			method = "GET",
			url = url,
			para = UrlDecode(para),
		}
	elseif IsPost(msg) then
		-- skip "POST"
		local msg = string.sub(msg, 6)
		-- find url
		local i, j = string.find(msg, " ")
		local url = string.sub(msg, 1, i - 1)
		local para
		local para_len
		while true do
			local msg, err = client:receive()
			if err then return { err_msg = err, } end

			if msg ~= "" then
				local i, j = string.find(msg, "Length: ")
				if i then
					para_len = string.sub(msg, j + 1)
				end
			else
				if not para_len then return { err_msg = "Parser POST req length failed.\n", } end

				para, err = client:receive(para_len)
				if err then return { err_msg = err, } end

				return {
					method = "POST",
					url = url,
					para = UrlDecode(para),
				}
			end
		end
	else
		return { err_msg = "Server doesn't support this HTTP method.\n", }
	end
end


while true do
	local client = server:accept()
	if client then
		local msg = RecvHttpMsg(client)
		if not msg.err_msg then
			-- 
			print("*************** receive a new request ***************")
			print("method: " .. msg.method)
			print("url: " .. msg.url)
			print("para: " .. msg.para)
			local cmd_handler = cmd.cmd_handlers[msg.url]
			if cmd_handler then
				local ret = cmd_handler.do_func(msg)
				if ret then
					client:send(cmd_handler.ret_func())
				else
					client:send(cmd.ErrRet("Server deal cmd failed.\n"))
				end
			else
				client:send(cmd.ErrRet("Unknown server cmd.\n"))
			end
		else
			client:send(cmd.ErrRet(msg.err_msg))
		end

		client:close()
	end
end