-- Copyright (C) by Cooper Lee


local modulename = "seaweedfs"
local _M = {}
local mt = { __index = _M }
_M._VERSION = '0.0.7'
_M._NAME = modulename


local resty_http = require "resty.http"
local cjson = require "cjson"

local setmetatable = setmetatable

local DEFAULT_HASH = "NONE"
local DEFAULT_SCHEMA = "http"

local req_data = function()
  local data = ngx.req.get_body_data()
  if (not data) then
    ngx.req.read_body()
    data = ngx.req.get_body_data()
    if (not data) then
      local body_file_path = ngx.req.get_body_file()
      if body_file_path then
        local file = io.open(body_file_path, "r")
        if file then
          data = file:read("*a")
          file:close()
        end
      end
    end
  end
  return data
end

local sha256 = function(data)
  local hash_data = data or req_data()
  if hash_data then
    local resty_sha256 = require "resty.sha256"
    local sha256 = resty_sha256:new()
    sha256:update(hash_data)
    local digest = sha256:final()
    local sha256_hash = ngx.encode_base64(digest)
    return sha256_hash
  end
end

local md5 = function(data)
  local hash_data = data or req_data()
  if hash_data then
    local resty_md5 = require "resty.md5"
    local md5 = resty_md5:new()
    md5:update(hash_data)
    local digest = md5:final()
    local md5_hash = ngx.encode_base64(digest)
    return md5_hash
  end
end

_M.new = function(self, options)
  self.master_url = options.master_url
  self.hash = options.hash or DEFAULT_HASH
  self.schema = options.schema or DEFAULT_SCHEMA
  self.http = resty_http.new()
  return setmetatable(self, mt)
end

_M.put = function(self,url,fid,data)
  local put_data = data or req_data()
  if not put_data then
    return nil, "no body data"
  end
  local res, err = self.http:request_uri(self.schema .. '://' .. url .. '/' .. fid,{
    method = "PUT",
    body = put_data,
    -- headers = {
    -- }
  })

  if res and res.status == 201 then
    ngx.log(ngx.INFO,"weedfs upload success:",fid)
    local result_info = cjson.decode(res.body)
    result_info.fid = fid
    if self.hash == 'SHA256' then
      result_info.sha256 = sha256(put_data)
    elseif self.hash == 'MD5' then
      result_info.md5 = md5(put_data)
    end
    res.body = cjson.encode(result_info)
  end
  return res, err

end

_M.delete = function(self,fid)
  return self.http:request_uri(self.schema .. '://' .. self.master_url .. '/' .. fid,{
    method = "DELETE",
  })
end

_M.assign = function(self)
  local request_url = self.schema .. '://' .. self.master_url .. "/dir/assign"
  return self.http:request_uri(request_url)
end

_M.lookup = function(self,volume_id)
  return self.http:request_uri(self.schema .. '://' .. self.master_url .. "/dir/lookup?volumeId="..volume_id)
end

_M.get = function(self,fid)
  local file_url = self.schema .. '://' .. self.master_url .. '/' .. fid
  local res, err = self.http:request_uri(file_url)
  if res and res.status >= 300 and res.status < 400 then
    -- file_url = res.headers["Location"]
    file_url = string.match(res.body,'"(.+)"')
    res, err = self.http:request_uri(file_url)
  end

  return res, err

end

_M.upload = function(self)
  local put_data = req_data()
  if not put_data then
    return nil,"no body data"
  end

  local res, err = self:assign()

  if not res then
    ngx.log(ngx.ERR,"weedfs assign error:",err)
    return res, err
  end

  if res.status ~= 200 then
    return res, err
  else
    ngx.log(ngx.INFO,"weedfs assign success:",res.body)
    local assing_info = cjson.decode(res.body) 
    return self:put(assing_info.publicUrl,assing_info.fid,put_data)
  end
end


return _M