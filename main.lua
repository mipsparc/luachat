function sanitizer(str)
    str = string.gsub(str, "[&<>\"']+", "")
    return str
end

if ngx.req.get_method() == "GET" then
    ngx.say([[
        <p>What is your name?</p>
        <form method="post" action="">
            <input type="text" name="name">
            <input type="submit">
        </form>
    ]])
else
    ngx.req.read_body()
    local args, err = ngx.req.get_post_args()
    local name = args["name"]
    if name then
        ngx.say("<p>Hello, ", sanitizer(name), "! </p>")
    end
end


