Remote Assistance server
======================

Setup and run
------------

Install yarn
```bash
$ brew install yarn
```

Install nvm
```bash
$ brew install nvm
```

Install node with nvm
```bash
$ nvm install 10.15.1
$ nvm use 10.15.1
```

Install node packages
``` bash
$ yarn install
```

Run
``` bash
$ yarn start
```

API
------------

Create a user
```
post /api/user
data {"type":"customer|expert","photo_url":"url_string","password":"","email":"email_string","name":"name_string"}
return {"id":int,"type":"customer|expert","photo_url":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}
```

Get user details
```
get /api/user/:uuid
return {"id":int,"type":"customer|expert","photo_url":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}
```

Get all users
```
get /api/user
return [{"id":int,"type":"customer|expert","photo_url":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}]
```

Update user
```
put|patch /api/user/:uuid
data {"type":"customer|expert","photo_url":"url_string","password":"","email":"email_string","name":"name_string"}
return {"id":int,"type":"customer|expert","photo_url":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}
```

Delete a user 
```
delete /api/user/:uuid
return {"uuid":"string"}
```


Create a room
```
post /api/room
data {time_ping":int,"time_request":int,"time_created":int}
return {"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string","experts":1,"customers":0}
```

Get room details
```
get /api/room/:uuid
return {"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string","experts":1,"customers":0}
```

Get all rooms
```
get /api/room
return [{"uuid":"test1","id":1,"time_ping":1,"time_request":2,"time_created":null,"experts":0,"customers":0}]
```

Get rooms with at least one participant
```
get /api/room?active=1
[{"uuid":"test1","id":1,"time_ping":1,"time_request":2,"time_created":null,"experts":1,"customers":0}]
```

Update room
```
put|patch /api/room/:uuid
data {time_ping":int,"time_request":int,"time_created":int}
return {"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string","experts":1,"customers":0}
```

Delete a room 
```
delete /api/room/:uuid
return {"uuid":"string"}
```


Create an anchor
```
post /api/anchor
data {"url":url,"type":"image|object","name":"string"}
return {"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}
```

Get anchor details
```
get /api/anchor/:uuid
return {"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}
```

Get all anchors
```
get /api/room
return [{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Get all anchors whose name includes a given string
```
get /api/room?text=string
return [{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Update anchor
```
put|patch /api/anchor/:uuid
data {"url":url,"type":"image|object","name":"string"}
return {"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}
```

Delete an anchor
```
delete /api/anchor/:uuid
return {"uuid":"string"}
```


Create clip
```
post /api/clip
data {"name":string,"user_uuid":string,"room_uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}
return {"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}
```

Get clip details
```
get /api/clip/:uuid
return {"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}
```

Get all clips (note since no anchor is given these must be without anchor positions)
```
get /api/clip
return [{"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}]
```

Get clips attached to anchor 
```
get /api/clip?anchor_uuid=string
return [{"position":"{}","id":75,"name":"demo1","user_uuid":"demo","room_uuid":"demo","uuid":"demo1","thumbnailUrl":url,"webmUrl":url,"mp4Url":url}]
```

Update clip
```
put|patch /api/clip/:uuid
data {"name":string,"user_uuid":string,"room_uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}
return {"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnail_url":url,"webm_url":url,"mp4_url":url}
```

Delete a clip
```
delete /api/clip/:uuid
return {"uuid":"string"}
```

Create clipAnchor
```
post /api/clipAnchor
data {"clip_uuid":string,"anchor_uuid":string,"position":json}
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Get clipAnchor details
```
get /api/clipAnchor/:uuid
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Get all clipAnchors
```
get /api/clipAnchor
return [{"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}]
```

Update clipAnchor
```
put|patch /api/clipAnchor/:uuid
data {"clip_uuid":string,"anchor_uuid":string,"position":json}
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Delete clipAnchor
```
delete /api/clipAnchor/:uuid
return {"uuid":"string"}
```

Delete clipAnchor given clip and anchor uuids
```
delete /api/clipAnchor/:clip_uuid/:anchor_uuid
return {"clip_uuid":"string","anchor_uuid":"string"}
```


Create userRoom
```
post /api/userRoom
data {"user_uuid":string,"room_uuid":string,"time_ping":string,"state":int}
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Get userRoom details
```
get /api/userRoom/:uuid
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Get all userRooms
```
get /api/userRoom
return [{"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}]
```

Update userRoom
```
put|patch /api/userRoom/:uuid
data {"user_uuid":string,"room_uuid":string,"time_ping":string,"state":int}
return {"id":int,"anchor_uuid":string,"clip_uuid":string,"position":json,"uuid":string}
```

Delete userRoom
```
delete /api/userRoom/:uuid
return {"uuid":"string"}
```

Delete userRoom given user and room uuids
```
delete /api/clipAnchor/:user_uuid/:room_uuid
return {"uuid":"string"}
```

