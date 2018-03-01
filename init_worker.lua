--cpu usage
--by sgx
--2018.01.21
--
local debug = 1
local cpu_um = ngx.shared.cpu_u;
local new_timer = ngx.timer.at
local function getcpu_usage()
	if (ngx.worker.id() ~= 0) then
	--	只运行在一个worker上面，多个worker并发没有必要，同时也会产生莫名其妙的问题。
	--	设定只运行在id为0的worker上面。
		return
	end
	local ok,err = new_timer(1,getcpu_usage)
	local cpufile = "/proc/stat"
	local fd = ffi.C.open(cpufile,O_RDONLY or O_NONBLOCK)
	if (fd == -1) then
		if (debug == 1) then
			ngx.log(ngx.ERR,"open -1")
		end
		return
	end
	
	local cbuf = ffi.new("char [2000]")
	local rd_num = ffi.C.read(fd,cbuf,2000)
	ffi.C.close(fd)
	if (rd_num == -1) then 
		if (debug == 1) then
			ngx.log(ngx.ERR,"read")
		end
--		ffi.C.close(fd) //close(fd)
		return
	end
	
	local buf = ffi.string(cbuf)
	local flag = string.find(buf,"\n")
	local firstline = string.sub(buf,0,flag)
	-- 第一行为cpu总体使用率信息，读取这一行，需要更多需要继续读取后面的N行，
	-- n表示cpu数量。
	
	local function split (str,pat)
		local t = {}
		local fpat = "(.-)" .. pat
		local last_end = 1
		local s,e,cap = str:find(fpat,1)
		while s do
			if s ~= 1 or cap ~= "" then
				table.insert(t,cap)
			end
			last_end = e+1
			s,e,cap = str:find(fpat,last_end)
		end
		if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t,cap)
		end
		return t
	end
	local cpu_u = split(firstline, ' ')
	local cpu_total = 0
	local cpu_idle = cpu_u[6]	-- tab索引，idle
	local cpu_time = cpu_um:get("time")
	local cpu_total_last = cpu_um:get("total")
	local cpu_idle_last = cpu_um:get("idle")
	local cpu_idle_now
	for k,v in pairs(cpu_u) do
		if (type(tonumber(v)) == "number") then
			cpu_total = cpu_total + tonumber(v)
		end
	end
	if ((cpu_time and cpu_total_last and cpu_idle_last) == nil) then
		--ngx.log(ngx.ERR,"nil")
		--return
		cpu_um:set("time",os.time())
		cpu_um:set("total",cpu_total)
		cpu_um:set("idle",cpu_idle)
		return 
	else
		cpu_idle_now = (cpu_idle - cpu_idle_last)/(cpu_total - cpu_total_last)
	end
	cpu_um:set("time",os.time())
	cpu_um:set("total",cpu_total)
	cpu_um:set("idle",cpu_idle)
	cpu_um:set("idle_per",cpu_idle_now)
	ngx.log(ngx.ERR,cpu_idle_now)
	--ngx.log(ngx.ERR,"idle:"..cpu_idle_now.."total:"..cpu_total .. "idle:" .. cpu_idle)
end
local ok,err = new_timer(1,getcpu_usage)
-- 不支持复杂数据，无法完成table存储，计算完毕后保存。
--[[

	local cpu_um_1,cpu_um_2 = cpu_um:get("one"),cpu_um:get("two")
	local time = os.time()
	local other = {}
	other[time] = time
	other[cpu_u] = cpu_u
	
	if (cpu_um_1 == nil) then
		cpu_um:set("one",other)
	elseif ((cpu_um_1 ~= nil) and (cpu_um_2 == nil)) then
		cpu_um:set("two",other)
	elseif ( cpu_um_1 and cpu_um_2) then
		if (cpu_um_1[time] < cpu_um_2[time]) then
			cpu_um:set("one",other)
		else
			cpu_um:set("two",other)
		end
	end
	cpu_um_t1,cpu_um_t2 = cpu_um:get("one"),cpu_um:get("two")
	if (cpu_um_1[time] > cpu_um_2[time]) then
		local total_1 = 0
		local total_2 = 0
		for k,v in pairs(cpu_um_1[cpu_u]) do
			if (type(v) == "number") then
				total_1 = total_1 + v
			end
		end
		for k,v in pairs(cpu_um_2[cpu_u]) do
			if (type(v) == "number") then
				total_2 = total_2 + v
			end
		end
		local cpu_us = 1-(cpu_um_1[cpu_u][6]-cpu_um_2[cpu_u][6])/(total_1 - total_2)
		ngx.log(ngx.ERR,"cpu_usage:" .. cpu_us)
	else
		local total_1 = 0
		local total_2 = 0
		for k,v in pairs(cpu_um_1[cpu_u]) do
			if (type(v) == "number") then
				total_1 = total_1 + v
			end
		end
		for k,v in pairs(cpu_um_2[cpu_u]) do
			if (type(v) == "number") then
				total_2 = total_2 + v
			end
		end
		local cpu_us = 1-(cpu_um_2[cpu_u][6]-cpu_um_1[cpu_u][6])/(total_2 - total_1)
		ngx.log(ngx.ERR,"cpu_usage:" .. cpu_us)
	end
--]]

