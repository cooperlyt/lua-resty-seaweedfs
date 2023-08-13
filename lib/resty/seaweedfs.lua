-- Copyright (C) by Cooper Lee


local modulename = "seaweedfs"
local _M = {}
local mt = { __index = _M }
_M._VERSION = '0.0.3'
_M._NAME = modulename


local resty_http = require "resty.http"
local cjson = require "cjson"

local setmetatable = setmetatable

local DEFAULT_HASH = "NONE"
local DEFAULT_SCHEMA = "http"

local sha256 = function()
  local resty_sha256 = require "resty.sha256"
  local sha256 = resty_sha256:new()
  sha256:update(ngx.req.get_body_data())
  local digest = sha256:final()
  local sha256_hash = ngx.encode_base64(digest)
  return sha256_hash
end

local md5 = function()
  local resty_md5 = require "resty.md5"
  local md5 = resty_md5:new()
  md5:update(ngx.req.get_body_data())
  local digest = md5:final()
  local md5_hash = ngx.encode_base64(digest)
  return md5_hash
end

_M.new = function(self, options)
  self.master_url = options.master_url
  self.hash = options.hash or DEFAULT_HASH
  self.schema = options.schema or DEFAULT_SCHEMA
  self.http = resty_http.new()
  return setmetatable(self, mt)
end

_M.put = function(self,url,fid)
  ngx.req.read_body()
  if not ngx.req.get_body_data() then
    return nil,"no body data"
  end
  return self.http:request_uri(self.schema .. '://' .. url .. '/' .. fid,{
    method = "PUT",
    body = ngx.req.get_body_data(),
    -- headers = {
    -- }
  })
end

_M.delete = function(self,fid)
  return self.http:request_uri(self.schema .. '://' .. self.master_url .. '/' .. fid,{
    method = "DELETE",
  })
end

_M.assign = function(self)
  local request_url = self.schema .. '://' .. self.master_url .. "/dir/assign"
  ngx.log(ngx.INFO,"weedfs assign:",request_url)
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
  local res, err = self:assign()

  if not res then
    ngx.log(ngx.ERR,"weedfs assign error:",err)
    return res, err
  end

  -- res.status , res.body

  if res.status ~= 200 then
    return res, err
  else
    local assing_info = cjson.decode(res.body)
    
    res, err = self:put(assing_info.publicUrl,assing_info.fid)
    if res.status ~= 201 then
      return res, err
    else
      ngx.log(ngx.INFO,"weedfs upload success:",assing_info.fid)
      local result_info = cjson.decode(res.body)
      result_info.fid = assing_info.fid
      if self.hash == 'SHA256' then
        result_info.sha256 = sha256()
      elseif self.hash == 'MD5' then
        result_info.md5 = md5()
      end
      res.body = cjson.encode(result_info)
      return res, err
    end
  end
end


return _M