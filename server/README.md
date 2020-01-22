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

Create a customer and return UUID
```
/api/createCustomer
```

Create an expert and return UUID
```
/api/createExpert
```

Get user details
```
/api/getUser/:uuid
```

Get all user UUIDs
```
/api/getAllUsers/
```

Create a room and return a UUID
```
/api/createRoom
```

Get room details
```
/api/getRoom/:uuid
```

Get rooms with at least one participant. Returns count of customers and experts in each room.
```
/api/getActiveRooms
```

Get all room UUIDs
```
/api/getAllRoom/
```

Associate user and room
```
/api/addUserToRoom/:room_uuid/:user_uuid
```

Disassociate user and room
```
/api/removeUserFromRoom/:room_uuid/:user_uuid
```

Get anchor details
```
/api/getAnchor/:uuid
```

Get details of all anchors whose name includes given text 
```
/api/getAnchors/:text
```

Get all anchor UUIDs
```
/api/getAllAnchors/
```

Get clip details
```
/api/getClip/:uuid
```

Get clip details for given anchor (optionally also select by room)
```
/api/getClips/:anchor_uuid/:room_uuid?
```

Associate clip and anchor
```
/api/addClipAnchor/:anchor_uuid/:clip_uuid/:position_blob
```

Create an entry for a clip and return UUID
```
/api/createClip/:name/:user_uuid/:room_uuid
```

Get all clip UUIDs
```
/api/getAllClips/
```

