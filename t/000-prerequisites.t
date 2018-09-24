use Test::Nginx::Socket 'no_plan';
run_tests();

__DATA__

=== TEST 1: nginx doesn't crash when using the Rollbar module
As long as the required environment variables are set, nothing should explode
--- main_config
env ROLLBAR_API_TOKEN;
--- config
    location = /t {
        content_by_lua_block {
            local rollbar = require("rollbar-nginx")
            ngx.print(os.getenv('ROLLBAR_API_TOKEN') == nil)
        }
    }
--- request
GET /t
--- response_body: false
--- error_code: 200


=== TEST 3: nginx should explode if environment variables aren't set
--- config
    location /t {
        content_by_lua_block {
            local rollbar = require("rollbar-nginx")
        }
    }
--- request
GET /t
--- error_code: 500
