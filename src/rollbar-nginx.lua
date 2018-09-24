local cjson = require('cjson')
local http = require('resty.http')

local rollbarHref = 'https://api.rollbar.com/api/1/'
local apiToken = os.getenv('ROLLBAR_API_TOKEN')

assert(apiToken ~= nil, 'Environment variable ROLLBAR_API_TOKEN not set')

local M = {}
local Helpers = {}

function M.createMessageItem(msg, environment, altApiToken, altHref)
  apiHref = altHref or rollbarHref
  token = altApiToken or apiToken
  env = environment or 'production'

  -- Create item details table

  local body = {
    ['access_token'] = token,
    data = {
      environment = env,
      body = {
        message = {
          body = msg
        }
      }
    }
  }

  -- Build and send request

  local httpc = http.new()
  local request = Helpers.buildRequest({}, body, 'POST')
  local res, err = httpc:request_uri(apiHref .. 'item/', request)
  if not res or res.status ~= 200 then
    return ngx.exit(res.status)
  end

  -- Finish the request

  local response = res.body
  Helpers.finish(res, response)
end

function Helpers.buildRequest(headers, body, method)
  local req = {
    method = method or ngx.var.request_method,
  }

  if headers then
    req['headers'] = {
      ['Content-Type'] = headers['Content-Type'],
      accept = 'application/json'
    }

    if headers['Authorization'] then
      req['headers']['Authorization'] = headers['Authorization']
    end
  end

  if body then
    req['body'] = cjson.encode(body)
  end
  return req
end

function Helpers.finish(res, response)
  ngx.status = res.status
  ngx.header.content_type = res.headers['Content-Type']
  ngx.header.cache_control = 'no-store'
  ngx.header.pragma = 'no-cache'
  ngx.say(cjson.encode(response))
  ngx.exit(ngx.HTTP_OK)
end

return M
