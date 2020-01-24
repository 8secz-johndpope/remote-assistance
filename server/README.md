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

Create a customer
```
/api/createCustomer
{"uuid":"string"}
```

Create an expert 
```
/api/createExpert
{"uuid":"string"}
```

Delete a user 
```
/api/deleteUser/:uuid
{"uuid":"string"}
```

Get user details
```
/api/getUser/:uuid
{"id":int,"type":"customer|expert","photo":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}
```

Get all users
```
/api/getAllUsers
[{"id":int,"type":"customer|expert","photo":"url_string","uuid":"string","password":"","email":"email_string","name":"name_string"}]
```

Create a room
```
/api/createRoom
{"uuid":"string"}
```

Delete a room 
```
/api/deleteRoom/:uuid
{"uuid":"string"}
```

Get room details
```
/api/getRoom/:uuid
{"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string","experts":1,"customers":0}
```

Get rooms with at least one participant
```
/api/getActiveRooms
[{"uuid":"test1","id":1,"time_ping":1,"time_request":2,"time_created":null,"experts":1,"customers":0}]
```

Get all rooms
```
/api/getAllRooms
[{"uuid":"test1","id":1,"time_ping":1,"time_request":2,"time_created":null,"experts":0,"customers":0}]
```

Add user to room
```
/api/addUserToRoom/:user_uuid/:room_uuid
{"user_uuid":"string","room_uuid":"string"}
```

Remove user from room
```
/api/removeUserFromRoom/:user_uuid/:room_uuid
{"user_uuid":"string","room_uuid":"string"}
```

Get anchor details
```
/api/getAnchor/:uuid
{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}

```

Get all anchors whose name includes given text 
```
/api/getAllAnchors/:text
[{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Get all anchors
```
/api/getAllAnchors
[{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Create clip
```
/api/createClip/:name/:user_uuid/:room_uuid
{"uuid":"152875912"}
```

Delete a clip 
```
/api/deleteClip/:uuid
{"uuid":"string"}
```

Get clip details. Data is available at uuid.webm, uuid.mp4, and uuid.jpg (thumbnail).
```
/api/getClip/:uuid
{"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnailUrl":url,"webmUrl":url,"mp4Url":url}
```

Get clip details (including position of clip on anchor) for given anchor (optionally also select by room)
```
/api/getClipsForAnchor/:anchor_uuid/:room_uuid?
[{"position_blob":"{}","id":75,"name":"demo1","user_uuid":"demo","room_uuid":"demo","uuid":"demo1","thumbnailUrl":url,"webmUrl":url,"mp4Url":url}]
```

Get all clips (note since no anchor is given these must be without anchor positions)
```
/api/getAllClips
[{"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string,"thumbnailUrl":url,"webmUrl":url,"mp4Url":url}]
```

Add clip to anchor at a positon
```
/api/addClipToAnchor/:clip_uuid/:anchor_uuid/:position_blob
{"anchor_uuid":string,"clip_uuid":string}
```

Remove clip from anchor
```
/api/removeClipFromAnchor/:clip_uuid/:anchor_uuid
{"anchor_uuid":string,"clip_uuid":string}
```
