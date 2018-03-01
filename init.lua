ffi = require "ffi"
bossapi = ffi.load("libbossapi_c.so")
ffi.cdef [[
        int open(const char *path,int oflag,...);
        int close(int fildes);
        unsigned int read(int fildes,void *buf,unsigned int nbyte);
        void *memcpy(void *restrict s1, const void *restrict s2, size_t n);
]]

-- 定义一些C语言常量，使ffi调用符合c习惯
O_RDONLY = 0
O_NONBLOCK = 2048

-- init lock
resty_lock = require "resty.lock"
cgi_lock = resty_lock:new("lock")
