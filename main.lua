local function sanitizer(str)
    local utf8 = require 'lua-utf8'
    str = utf8.gsub(str, "[<>\"'\n]+", "")
    str = utf8.gsub(str, '&#(%d+);', function(n) return utf8.char(n) end)
    str = utf8.gsub(str, '&#x(%d+);', function(n) return utf8.char(tonumber(n,16)) end)
    str = utf8.gsub(str, "&+", "&amp;")
    return str
end

local function redis_init()
    local redis = require "resty.redis"
    local redisObject, err = redis:new()
    if redisObject == nil then
        ngx.say("connection err", err)
        return
    end
    local ok, err = redisObject:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("connection err", err)
        return
    end
    return redisObject
end

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local function randomString(length)
    local seed = 0
    local seed_str = io.open('/dev/urandom', 'rb'):read(8)
    for i = 1, 8 do
        seed = seed + string.byte(seed_str, i)
    end
    math.randomseed(seed)
    local out = ""
    for i = 1, length do
        out = out .. charset[math.random(1, #charset)]
    end
    return out
end

local function cookie_init()
    local ck = require "resty.cookie"
    local cookie, err = ck:new()
    if err then
        ngx.err("error")
    end
    return cookie
end

if ngx.req.get_method() == "GET" then
    cookie = cookie_init()
    redisObject = redis_init()

    local sessid, err = cookie:get("sess")
    if not sessid or redisObject:sismember("sess", sessid) ~= 1 then
        sessid = randomString(32)
        redisObject:sadd("sess", sessid)
        local ok, err = cookie:set({
            key = "sess", value = sessid, path = "/",
            domain = "35.221.102.183", httponly = true,
            max_age = 300, samesite = "Strict"
        })
    end
    ngx.say([[
        <!DOCTYPE html>
        <head><meta charset="UTF-8"></head>
        <body>
        <p>What is your name?</p>
        <form method="post" action="">
            <input type="text" name="name">
            <input type="hidden" name="sess" value="]] .. sessid .. [[">
            <input type="submit">
        </form>
        </body>
        </html>
    ]])
    local names = redisObject:sinter("names")
    for i = 1, #names do
        ngx.say("<p>" .. names[i] .. "</p>")
    end

else
    ngx.req.read_body()
    local args, err = ngx.req.get_post_args()
    local name = sanitizer(args["name"])
    local sessid = args["sess"]
    if name and sessid then
        redisObject = redis_init()
        if redisObject:sismember("sess", sessid) == 1 then
            redisObject:sadd("names", name)
        end
    end
    return ngx.redirect("/")
end


