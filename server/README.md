Remote Assistance server
======================

Prerequisites
-------------

* Install nvm

  *Mac:*
  ```bash
  $ brew install nvm
  $ cat << EOF >> ~/.bash_profile
  export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"
  EOF
  ```

  *Windows:*
  
  Download and install: https://github.com/coreybutler/nvm-windows

* Install Node.js
  ```
  $ nvm install 10.15.1
  $ nvm use 10.15.1
  ```
 
* Install yarn
  ```
  $ npm install -g yarn
  ```

* Install leapmotion

  1. Download Leapmotion software: https://developer.leapmotion.com/setup/desktop
     * Windows users download V4 Orion version
     * Mac and Linux users download V2 version
  2. Start the `Leapmotion Control Panel` app
  3. Check `Allow Web Apps` under the `General` panel
  4. Check `Allow Background Apps` under the `General` panel
  
  
  ![Leapmotion Control Panel](https://i.imgur.com/3Mjsiwn.jpg "Leapmotion Control Panel")



Setup and run
------------

Install node packages
``` bash
$ yarn install
```

Run
``` bash
$ yarn start
```

Install and run MySQL and then import the DB configuration
``` bash
mysql -u username -p database_name < aceDBConfiguration.sql
```
Note that aceDBConfiguration.sql includes only table information whereas aceDBConfigurationWithData.sql includes table and data info.

Connect with browser
--------------------

1. Customer uses iOS app or connects with a browser
2. Expert opens https://[ip-address]:5443/ and clicks on expert


Chat UI
-----------------
The chat interface takes as input a decision tree stored as a JSON file in static/js/chat.tree.js. Please see [see this example](static/js/chat.tree.example.js). Each entry in the responses array has an *id*, *question*, and a *next* array. Each entry can also optionally include a *nextLabels* array. *next* is an array of *ids* to which the user can navigate after the current question. Each entry in the *next* array is converted to a button with a label set in the *nextLabels* array. If the *nextLabels* array is not set, label names are set to *id* names. For example, in this case:

```
"id": 5,
"q": "Great. Would you like 1) help fixing my printer 2) help ordering printer parts or 3) to speak with someone?",
"next": [6,7,8],
"nextLabels": ["1","2","3"]
  ```

The user will see the question "Great. Would you like 1) help fixing my printer 2) help ordering printer parts or 3) to speak with someone?" followed by three buttons labeled "1", "2", and "3" which will navigate them to questions with *ids* 6, 7, and 8 respectively. 

Note that there are some special cases for the *next* array:
- Phone numbers and email addresses are converted to phone call and email buttons respectively.
- Text "ra" will generate a button that launches the remote assistance application.
- Text "barcode" followed by a single *id* indicates that the app will navigate to question *id* after the user scans a barcode. If setVar is also present, the payload of the barcode is also set to that variable name.
- Valid web addresses are automatically converted to hotlinked icons in the chat. 
- The next array supports device-specific branching. This has the form #m#m# (e.g., "15m16m17"). This redirects the user to different branches based on whether they are using an Android, iOS, or other device (e.g., in this example, if the user is using an Android device, they would be redirected to question 15, if they are using an iOS device they would be redirected to 16, and in any other case they would be redirected to question 17).

API Documentation
-----------------

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
data {type":"image|object","name":"string"}
data file (any name)
return {"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}
```

Get anchor details
```
get /api/anchor/:uuid
return {"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}
```

Get all anchors
```
get /api/anchor
return [{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Get all anchors whose name includes a given string
```
get /api/anchor?text=string
return [{"id":int,"uuid":"string","url":url,"type":"image|object","name":"string"}]
```

Update anchor
```
put|patch /api/anchor/:uuid
data {type":"image|object","name":"string"}
data file (any name)
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
return [{"position":"{}","id":75,"name":"demo1","user_uuid":"demo","room_uuid":"demo","uuid":"demo1","thumbnail_url":url,"webm_url":url,"mp4_url":url}]
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
delete /api/userRoom/:user_uuid/:room_uuid
return {"uuid":"string"}
```

Get error code details
```
get /api/errorCode/:uuid
return {"id":int,url":"url_string","code":"string"}
```

Get all error codes
```
get /api/errorCode
return [{"id":int,url":"url_string","code":"string"}]
```

Get printer details
```
get /api/printerName/:name
return {"id":int,name":"string",partsList:"string"}
```

Get all printers
```
get /api/printerName
return [{"id":int,name":"string",partsList:"string"}]
```
