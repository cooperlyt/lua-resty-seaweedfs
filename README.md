# lua-resty-seaweedfs

Lua seaweedfs client with [seaweedfs](https://github.com/seaweedfs/seaweedfs).

Status
=======
Production ready.


[![CI](https://github.com/cooperlyt/lua-resty-seaweedfs/actions/workflows/seaweedfs-gateway.yml/badge.svg)](https://github.com/cooperlyt/lua-resty-seaweedfs/actions)

USESAGE
=======
  + Implement seaweedfs API

  + One step updoad file
  
  + Result Add request file hash code

  + Return image thumb

API
=======

```lua
local seaweedfs = require "resty.seaweedfs"
```
+ new

+ put

+ get

+ delete

+ assign

+ lookup

+ upload

Openresty

+ http://${url}/file/upload

+ http://${url}/file/img/7,26c02a5ef3

+ http://${url}/file/img/thumb/7,26c02a5ef3

+ http://${url}/file/get/7,26c02a5ef3

+ http://${url}/file/download/7,26c02a5ef3

Install
=======
  opm get cooperlyt/lua-resty-seaweedfs

  docker image [coopersoft/seaweedfs-gateway](https://hub.docker.com/repository/docker/coopersoft/seaweedfs-gateway/general)

Dependency
=======
  [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
  opm get ledgetech/lua-resty-http