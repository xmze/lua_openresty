local ffi = require "ffi"
local _M = { _VERSION = '0.01' }
ffi.cdef [[
	int getloadavg(double loadavg[],int nelem);
	int open(const char *path,int oflag,...);
	unsigned int read(int fildes,void *buf,unsigned int nbyte);
	void *memcpy(void *restrict s1,const void *restrict s2,size_t n);
	int close(int fd);
	int sscanf(const char *restrict s,const char *restrict format,...);
	int write(int fildes,const void *buf,size_t nbyte);
	int printf(const char *restrict format,...);
	int sprintf(char *restrict s,const char *restrict format, ...);
]]

local O_RDONLY = 0
local O_NONBLOCK = 2048

function _M.getloadavg()
	local a,b,c
	local loadavg = ffi.new("double [3]")
	if (ffi.C.getloadavg(loadavg,3) == -1) then
		return -1,-1,-1
	else
		return loadavg[0],loadavg[1],loadavg[2]
	end
end
function _M.getcpu_time_linux()
	local cpufile = "/proc/stat"
	local fd = ffi.C.open(cpufile,O_RDONLY or O_NONBLOCK)
	if (fd == -1) then
		return nil
	end
	local cbuf = ffi.new("char [2000]")
	local rd_num = ffi.C.read(fd,cbuf,2000)
	ffi.C.close(fd)
	if (rd_num == -1) then
		return nil
	end
	local user = ffi.new("long long[0]")
	local nice = ffi.new("long long[0]")
	local kernel = ffi.new("long long[0]")
	local idle = ffi.new("long long[0]")
	local iowait = ffi.new("long long[0]")
	ffi.C.sscanf(cbuf,"cpu %lld %lld %lld %lld %lld",
				user,nice,kernel,idle,iowait)
	local function longtonum(clong)
		local uu = ffi.new("char [50]",0)
		ffi.C.sprintf(uu,"%lld",clong)
		return tonumber(ffi.string(uu))
	end
	return longtonum(user[0]),longtonum(nice[0]),longtonum(kernel[0]),
				longtonum(idle[0]),longtonum(iowait[0])
end

function _M.getcpu_time()
	if (ffi.os == "Linux") then
		return _M.getcpu_time_linux()
	else
		return nil
	end
end
return _M
