local cpu_usage = ngx.shared.cpu_usage
local new_timer = ngx.timer.at
local loadavg = require "sgx.load"

local function getcpu_usage()
	new_timer(1,getcpu_usage)
	if (ngx.worker.id() ~= 0) then
		return
	-- must only one worker run
	end
	local flag = 0
	local t0,u0,n0,k0,i0,ii0 = cpu_usage:get("time0"),
					cpu_usage:get("user0"),
					cpu_usage:get("nice0"),
					cpu_usage:get("kernel0"),
					cpu_usage:get("idle0"),
					cpu_usage:get("iowait0")
	local t1,u1,n1,k1,i1,ii1 = cpu_usage:get("time1"),
					cpu_usage:get("user1"),
					cpu_usage:get("nice1"),
					cpu_usage:get("kernel1"),
					cpu_usage:get("idle1"),
					cpu_usage:get("iowait1")
	local user,nice,kernel,idle,iowait = loadavg.getcpu_time()
	if (t0 == nil) then
		flag = 0	
	elseif(t1 == nil) then
		flag = 1
	elseif(t1 > t0) then
		flag = 0
	else
		flag = 1
	end
	if (flag == 0) then
		--t0,u0,n0,k0,i0,ii0 = os.time(),user,nice,kernel,idle,iowait
		cpu_usage:set("time0",os.time())
		cpu_usage:set("user0",user)
		cpu_usage:set("nice0",nice)
		cpu_usage:set("kernel0",kernel)
		cpu_usage:set("idle0",idle)
		cpu_usage:set("iowait0",iowait)
	else
		--t1,u1,n1,k1,i1,ii1 = os.time(),user,nice,kernel,idle,iowait
		cpu_usage:set("time1",os.time())
		cpu_usage:set("user1",user)
		cpu_usage:set("nice1",nice)
		cpu_usage:set("kernel1",kernel)
		cpu_usage:set("idle1",idle)
		cpu_usage:set("iowait1",iowait)
	end
	t0,u0,n0,k0,i0,ii0 = cpu_usage:get("time0"),
					cpu_usage:get("user0"),
					cpu_usage:get("nice0"),
					cpu_usage:get("kernel0"),
					cpu_usage:get("idle0"),
					cpu_usage:get("iowait0")
	t1,u1,n1,k1,i1,ii1 = cpu_usage:get("time1"),
					cpu_usage:get("user1"),
					cpu_usage:get("nice1"),
					cpu_usage:get("kernel1"),
					cpu_usage:get("idle1"),
					cpu_usage:get("iowait1")
	if ((t0 and t1) == nil) then
		return
	end
	ngx.log(ngx.ERR,"idle(%):" .. (i1-i0)/(u1+n1+k1+i1+ii1-u0-n0-k0-i0-ii0))
end
local ok,err = new_timer(1,getcpu_usage)
