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

Get room details
```
/api/getRoom/:uuid
{"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string"}
```

Get rooms with at least one participant. Additionally returns count of customers and experts in each room.
```
/api/getActiveRooms
[{"uuid":"test1","id":1,"time_ping":1,"time_request":2,"time_created":null,"experts":1,"customers":0}]
```

Get all rooms
```
/api/getAllRooms
[{"id":int,"time_ping":int,"time_request":int,"time_created":int,"uuid":"string"}]
```

Associate user and room
```
/api/addUserToRoom/:user_uuid/:room_uuid
{"user_uuid":"string","room_uuid":"string"}
```

Disassociate user and room
```
/api/removeUserFromRoom/:user_uuid/:room_uuid
{"user_uuid":"string","room_uuid":"string"}
```

Get anchor details
```
/api/getAnchor/:uuid
{"id":int,"uuid":"string","data":"string","type":"image|object","name":"string"}

```

Get all anchors whose name includes given text 
```
/api/getAllAnchors/:text
[{"id":int,"uuid":"string","data":"string","type":"image|object","name":"string"}]
```

Get all anchors
```
/api/getAllAnchors
[{"id":int,"uuid":"string","data":"string","type":"image|object","name":"string"}]
```

Get clip details
```
/api/getClip/:uuid
{"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string}
```

Get clip details for given anchor (optionally also select by room)
```
/api/getClips/:anchor_uuid/:room_uuid?

```

Associate clip and anchor
```
/api/addClipAnchor/:anchor_uuid/:clip_uuid/:position_blob

```

Create an entry for a clip
```
/api/createClip/:name/:user_uuid/:room_uuid
{"uuid":"152875912"}
```

Get all clips
```
/api/getAllClips
[{"id":int,"name":string,"user_uuid":string,"room_uuid":string,"uuid":string}]
```

