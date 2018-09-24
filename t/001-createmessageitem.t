use Test::Nginx::Socket 'no_plan';
run_tests();

__DATA__

=== TEST 1: rollbar.createMessageItem exits when the POST /item request > 200
--- main_config
env ROLLBAR_API_TOKEN;
--- config
    location = /mock/item/ {
        content_by_lua_block {
            ngx.header.content_type = 'application/json'
            ngx.exit(400)
        }
    }

    location = /t {
        content_by_lua_block {
            local rollbar = require('rollbar-nginx')
            rollbar.createMessageItem('test', 'test', 'test token', 'http://127.0.0.1:1984/mock/')
        }
    }
--- more_headers
Content-type: application/json
--- request
GET /t
--- ignore_response_body
--- error_code: 400


=== TEST 2: rollbar.createMessageItem happy path
--- main_config
env ROLLBAR_API_TOKEN;
--- config
    location = /mock/item/ {
        content_by_lua_block {
            local cjson = require('cjson')

            ngx.req.read_body()
            local body = cjson.decode(ngx.req.get_body_data())
            assert(body['access_token'] == 'test token')
            assert(body['data'])
            assert(body['data']['environment'] == 'test')
            assert(body['data']['body'])
            assert(body['data']['body']['message'])
            assert(body['data']['body']['message']['body'] == 'test')

            ngx.exit(200)
        }
    }

    location = /t {
        content_by_lua_block {
            local rollbar = require('rollbar-nginx')
            rollbar.createMessageItem('test', 'test', 'test token', 'http://127.0.0.1:1984/mock/')
        }
    }
--- more_headers
Content-type: application/json
--- request
GET /t
--- error_code: 200
