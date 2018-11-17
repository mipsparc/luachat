
if ngx.req.get_method == "GET" then
    ngx.say([[
        <form method="post" action="">
            <input type="text" name="name">
            <input type="submit">
        </form>
    ]])
else
    local args, err = ngx.req.get_uri_args()
    local total = 0
    if not err then
        for key, val in pairs(args) do
        if type(tonumber(val)) == "number" then
                total = total + tonumber(val)
            end
        end

        ngx.say(total)
    end
end
