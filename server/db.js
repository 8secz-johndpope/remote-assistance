const mysql = require('mysql')
const config = require('config');
const parseDbUrl = require("parse-database-url");
const databaseConfig = parseDbUrl(config.databaseUrl);
const util = require('./util');
const fs = require('fs');

// handle disconnect
var connection;
function handleDisconnect() {
    connection = mysql.createConnection(databaseConfig);  // Recreate the connection, since the old one cannot be reused.
    connection.connect( function onConnect(err) {   // The server is either down
        if (err) {                                  // or restarting (takes a while sometimes).
            console.log('Error when connecting to db:', err);
			setTimeout(handleDisconnect, 10000);    // We introduce a delay before attempting to reconnect,
			return;
		}                                           // to avoid a hot loop, and to allow our node script to
		console.log(`Connected to mysql: ${databaseConfig.host}/${databaseConfig.database}`);
    });                                             // process asynchronous requests in the meantime.
                                                    // If you're also serving http, display a 503 error.
    connection.on('error', function onError(err) {
        console.log('DB Error:', err);
        if (err.code == 'PROTOCOL_CONNECTION_LOST') {   // Connection to the MySQL server is usually
            handleDisconnect();                         // lost due to either server restart, or a
        } else {                                        // connnection idle timeout (the wait_timeout
            throw err;                                  // server variable configures this)
        }
    });
}
handleDisconnect();

module.exports = {
	
	getConnection: () => {
		return connection
	},

	getRoom: (res,uuid,cb) => {
		connection.query('select * from room where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let ret = {}
				if (rows.length > 0) {
					ret = { uuid: rows[0].uuid, id: rows[0].id, time_ping: rows[0].time_ping, time_request: rows[0].time_request, time_created: rows[0].time_created, experts: 0, customers: 0 };
				}
				cb(ret);
		})		
	},

	getActiveRooms: (res,ret,roomName,cb) => {
		let q = 'SELECT userRoom.room_uuid,user.type,room.* FROM userRoom,user,room where userRoom.state = 1 and user.uuid = userRoom.user_uuid and room.uuid = userRoom.room_uuid';
		let arr = [];
		if (roomName !== null) {
			q += ' and userRoom.room_uuid = ?';
			arr.unshift(roomName);
		}
		connection.query(q,				
			arr
			,
			function (err, rows, fields) {
				if (err) throw err
				for (let i = 0; i < rows.length; i++) {
					let ru = rows[i].room_uuid; 
					let t = rows[i].type;
					let index = ret.findIndex(x => x.uuid === ru);

					if (index < 0) {
						let obj = { uuid: ru, id: rows[i].id, time_ping: rows[i].time_ping, time_request: rows[i].time_request, time_created: rows[i].time_created, experts: 0, customers: 0 };
						ret.unshift(obj);
						index = 0;
					}
					if (t == "expert") { ret[index].experts = ret[index].experts+1; ret.push(ret.splice(index, 1)[0]); }
					if (t == "customer") { ret[index].customers = ret[index].customers+1; }
				}
				cb(ret);
		})		
	},

	getAllRooms: (res,cb) => {
		connection.query('select * from room',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				let ret = []
				for (let i = 0; i < rows.length; i++) {
					let obj = { uuid: rows[i].uuid, id: rows[i].id, time_ping: rows[i].time_ping, time_request: rows[i].time_request, time_created: rows[i].time_created, experts: 0, customers: 0 };
					ret.unshift(obj);
				}
				cb(ret);
		})		
	},

	getAnchor: (res,uuid,cb) => {
		connection.query('select * from anchor where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				if (r.url) { r.url = config.anchorLoc + r.url; }
				cb(r)
		})		
	},

	createAnchor: (res,type,cb) => {
		let uuid = util.generateRandomId();
		connection.query('insert into anchor(uuid,type) values(?,?)',
			[
				uuid,
				type
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	deleteAnchor: (res,uuid,cb) => {
		connection.query('delete from anchor where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateAnchor: (res,insert,put,uuid,req,cb) => {
		let fp = null;
		if (req.files && (Object.entries(req.files).length > 0)) {
			let fns = Object.keys(req.files)
			let fo = req.files[fns[0]]
			console.log(fo)
			fp = uuid + '.' + fo.filename.split('.').pop()
			fs.readFile(fo.file, function (err, data) {
			  fs.writeFile(config.anchorLoc + fp, data, function (err) {
			  });
			});
		}
		let body = req.body;
		let q;
		if (insert) {
			q = 'insert into ';
		} else {
			q = 'update ';
		}
		q += ' anchor set ';
		let arr = [];
		let qArr = [];
		if (typeof body.type !== 'undefined') { qArr.push('type = ?'); arr.push(body.type); }
		else if (put) { qArr.push('type = "none"'); }
		if (typeof body.name !== 'undefined') { qArr.push('name = ?'); arr.push(body.name); }
		else if (put) { qArr.push('name = ""'); }
		if (fp !== null) { qArr.push('url = ?'); arr.push(fp); }
		else if (put) { qArr.push('url = ""'); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }
		if (qArr.length > 0) {
			connection.query(q,
				arr,
				function (err, result) {
					if (err) throw err
					let obj = {'uuid': uuid }	
					cb(obj)
			})			
		} else {
			let obj = {'uuid': uuid }	
			cb(obj)
		}
	},

	getAllAnchorsSearch: (res,text,cb) => {
		connection.query('select * from anchor where name like ?',
			[
				'%'+text+'%'
			],
			function (err, rows, fields) {
				if (err) throw err
				for (let i=0; i < rows.length; i++) {
					if (rows[i].url) { rows[i].url = config.anchorLoc + rows[i].url; }
				}
				cb(rows)
		})		
	},

	getAllAnchors: (res,cb) => {
		connection.query('select * from anchor ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				for (let i=0; i < rows.length; i++) {
					if (rows[i].url) { rows[i].url = config.anchorLoc + rows[i].url; }
				}
				cb(rows)
		})		
	},

	getClip: (res,uuid,cb) => {
		connection.query('select * from clip where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				if (rows.length > 0) {
					r.thumbnail_url = config.clipLoc + r.uuid + ".jpg";
					r.webm_url = config.clipLoc + r.uuid + ".webm";
					r.mp4_url = config.clipLoc + r.uuid + ".mp4";
				}
				cb(r)
		})		
	},

	getClipsForAnchor: (res,anchor_uuid,cb) => {
		let q = 'select clipAnchor.position,clip.* from clip,clipAnchor where clipAnchor.clip_uuid=clip.uuid and clipAnchor.anchor_uuid = ?'
		let arr = [anchor_uuid]; 
		//if (room_uuid) {
		//	q += ' and clip.room_uuid = ?'
		//	arr.push(room_uuid)
		//}
		connection.query(q,
			arr,
			function (err, rows, fields) {
				if (err) throw err
				for (let i=0; i < rows.length; i++) {
					rows[i].thumbnail_url = config.clipLoc + rows[i].uuid + ".jpg";
					rows[i].webm_url = config.clipLoc + rows[i].uuid + ".webm";
					rows[i].mp4_url = config.clipLoc + rows[i].uuid + ".mp4";
				}
				cb(rows)
		})		
	},

	getAllClips: (res,cb) => {
		connection.query('select * from clip ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				for (let i=0; i < rows.length; i++) {
					rows[i].thumbnail_url = config.clipLoc + rows[i].uuid + ".jpg";
					rows[i].webm_url = config.clipLoc + rows[i].uuid + ".webm";
					rows[i].mp4_url = config.clipLoc + rows[i].uuid + ".mp4";
				}
				cb(rows)
		})		
	},

	getUser: (res,uuid,cb) => {
		connection.query('select * from user where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				cb(r)
		})
	},

	createUser: (res,type,cb) => {
		let uuid = util.generateRandomId();
		connection.query('insert into user(uuid,type) values(?,?)',
			[
				uuid,
				type
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	deleteUser: (res,uuid,cb) => {
		connection.query('delete from user where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateUser: (res,insert,put,uuid,body,cb) => {
		let q;
		if (insert) {
			q = 'insert into ';
		} else {
			q = 'update ';
		}
		q += ' user set ';
		let arr = [];
		let qArr = [];
		if (typeof body.type !== 'undefined') { qArr.push('type = ?'); arr.push(body.type); }
		else if (put) { qArr.push('type = "none"'); }
		if (typeof body.photo_url !== 'undefined') { qArr.push('photo_url = ?'); arr.push(body.photo_url); }
		else if (put) { qArr.push('photo_url = ""'); }
		if (typeof body.email !== 'undefined') { qArr.push('email = ?'); arr.push(body.email); }
		else if (put) { qArr.push('email = ""'); }
		if (typeof body.password !== 'undefined') { qArr.push('password = ?'); arr.push(body.password); }
		else if (put) { qArr.push('password = ""'); }
		if (typeof body.name !== 'undefined') { qArr.push('name = ?'); arr.push(body.name); }
		else if (put) { qArr.push('name = "" '); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }

		if (qArr.length > 0) {
			connection.query(q,
				arr,
				function (err, result) {
					if (err) throw err
					let obj = {'uuid': uuid }	
					cb(obj)
			})			
		} else {
			let obj = {'uuid': uuid }	
			cb(obj)
		}
	},

	createRoom: (res,cb) => {
		let uuid = util.generateRandomId();
		let now = new Date() / 1000;
		connection.query('insert into room(uuid,time_created) values(?,?)',
			[
				uuid,
				now
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateRoom: (res,insert,put,uuid,body,cb) => {
		let q;
		if (insert) {
			q = 'insert into ';
			body.time_created = Date.now();
		} else {
			q = 'update ';
		}
		q += ' room set ';
		let qArr = [];
		let arr = [];
		if (typeof body.time_created !== 'undefined') { qArr.push('time_created = ?'); arr.push(body.time_created); }
		else if (put) { qArr.push('time_created = 0'); }
		if (typeof body.time_ping !== 'undefined') { qArr.push('time_ping = ?'); arr.push(body.time_ping); }
		else if (put) { qArr.push('time_ping = 0'); }
		if (typeof body.time_request !== 'undefined') { qArr.push('time_request = ?'); arr.push(body.time_request); }
		else if (put) { qArr.push('time_request = 0'); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }

		if (qArr.length > 0) {
			connection.query(q,
				arr,
				function (err, result) {
					if (err) throw err
					let obj = {'uuid': uuid }	
					cb(obj)
			})			
		} else {
			let obj = {'uuid': uuid }	
			cb(obj)
		}
	},

	deleteRoom: (res,uuid,cb) => {
		connection.query('delete from room where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	createClip: (res,name,user,room,cb) => {
		let uuid = util.generateRandomId();
		connection.query('insert into clip(uuid,name,user_uuid,room_uuid) values(?,?,?,?)',
			[
				uuid,
				name,
				user,
				room
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	deleteClip: (res,uuid,cb) => {
		connection.query('delete from clip where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateClip: (res,insert,put,uuid,body,cb) => {
		let q;
		if (insert) {
			q = 'insert into ';
		} else {
			q = 'update ';
		}
		q += ' clip set ';
		let arr = [];
		let qArr = [];
		if (typeof body.name !== 'undefined') { qArr.push('name = ?'); arr.push(body.name); }
		else if (put) { qArr.push('name = ""'); }
		if (typeof body.user_uuid !== 'undefined') { qArr.push('user_uuid = ?'); arr.push(body.user_uuid); }
		else if (put) { qArr.push('user_uuid = 0'); }
		if (typeof body.room_uuid !== 'undefined') { qArr.push('room_uuid = ?'); arr.push(body.room_uuid); }
		else if (put) { qArr.push('room_uuid = 0'); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }

		if (qArr.length > 0) {
			connection.query(q,
				arr,
				function (err, result) {
					if (err) throw err
					let obj = {'uuid': uuid }	
					cb(obj)
			})			
		} else {
			let obj = {'uuid': uuid }	
			cb(obj)			
		}
	},

	getAllUsers: (res,cb) => {
		connection.query('select * from user ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getAllClipAnchors: (res,cb) => {
		connection.query('select * from clipAnchor ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getClipAnchor: (res,uuid,cb) => {
		connection.query('select * from clipAnchor where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				cb(r)
		})
	},

	addClipToAnchor: (res,anchor_uuid,clip_uuid,position,cb) => {
		let uuid = util.generateRandomId();
		let q = 'insert into clipAnchor(anchor_uuid,clip_uuid,position,uuid) values(?,?,?,?)';
		connection.query(q,
			[
				anchor_uuid,
				clip_uuid,
				position,
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid}	
				cb(obj)
		})
	},

	
	removeClipFromAnchor: (res,anchor_uuid,clip_uuid,cb) => {
		let q = 'delete from clipAnchor where anchor_uuid = ? and clip_uuid = ?';
		connection.query(q,
			[
				anchor_uuid,
				clip_uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'anchor_uuid': anchor_uuid,'clip_uuid': clip_uuid}	
				cb(obj)
		})
	},

	deleteClipAnchor: (res,uuid,cb) => {
		connection.query('delete from clipAnchor where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateClipAnchor: (res,insert,put,uuid,body,cb) => {
		let q;
		if (insert) {
			q = 'insert into ';
		} else {
			q = 'update ';
		}
		q += ' clipAnchor set ';
		let arr = [];
		let qArr = [];
		if (typeof body.clip_uuid !== 'undefined') { qArr.push('clip_uuid = ?'); arr.push(body.clip_uuid); }
		else if (put) { qArr.push('clip_uuid = "none"'); }
		if (typeof body.anchor_uuid !== 'undefined') { qArr.push('anchor_uuid = ?'); arr.push(body.anchor_uuid); }
		else if (put) { qArr.push('anchor_uuid = ""'); }
		if (typeof body.position !== 'undefined') { qArr.push('position = ?'); arr.push(body.position); }
		else if (put) { qArr.push('position = ""'); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }

		connection.query(q,
			arr,
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	addUserToRoom: (res,room_uuid,user_uuid,cb) => {
		let now = new Date() / 1000;
		connection.query('select * from userRoom where user_uuid = ? and room_uuid = ?',
			[
				user_uuid,
				room_uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				if (rows.length > 0) {
					let uuid = rows[0]["uuid"];
					connection.query('update userRoom set time_ping = ?, state = ? where room_uuid = ? and user_uuid = ?',
						[
							now,
							1,
							room_uuid,
							user_uuid
						],
					function (err, rows, fields) {
						if (err) throw err
						let obj = {'uuid': uuid}	
						cb(obj)
					})
				} else {
					let uuid = util.generateRandomId();
					connection.query('insert into userRoom(room_uuid,user_uuid,time_ping,state,uuid) values(?,?,?,?,?) '
						,
						[
							room_uuid,
							user_uuid,
							now,
							1,
							uuid
						],
						function (err, rows, fields) {
							if (err) throw err
							let obj = {'uuid': uuid}	
							cb(obj)
					})					
				}
			})
	},

	removeUserFromRoom: (res,room_uuid,user_uuid,cb) => {
		let now = new Date() / 1000;
		connection.query('update userRoom set time_ping = ?, state = ? where room_uuid = ? and user_uuid = ?',
			[
				now,
				0,
				room_uuid,
				user_uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let obj = {'room_uuid': room_uuid,'user_uuid': user_uuid}	
				cb(obj)
		})
	},

	deleteUserRoom: (res,uuid,cb) => {
		connection.query('delete from userRoom where uuid = ?',
			[
				uuid
			],
			function (err, result) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	},

	updateUserRoom: (res,insert,put,uuid,body,cb) => {
		let q;
		if (insert) {
			q = 'insert into ';
		} else {
			q = 'update ';
		}
		q += ' userRoom set ';
		let arr = [];
		let qArr = [];
		if (typeof body.room_uuid !== 'undefined') { qArr.push('room_uuid = ?'); arr.push(body.room_uuid); }
		else if (put) { qArr.push('room_uuid = "none"'); }
		if (typeof body.user_uuid !== 'undefined') { qArr.push('user_uuid = ?'); arr.push(body.user_uuid); }
		else if (put) { qArr.push('user_uuid = ""'); }
		if (typeof body.time_ping !== 'undefined') { qArr.push('time_ping = ?'); arr.push(body.time_ping); }
		else if (put) { qArr.push('time_ping = 0'); }
		if (typeof body.state !== 'undefined') { qArr.push('state = ?'); arr.push(body.state); }
		else if (put) { qArr.push('state = 0'); }
		if (insert) { qArr.push('uuid = ?'); arr.push(uuid); }
		q += qArr.join(',');
		if (!insert) { q += ' where uuid = ?'; arr.push(uuid); }

		if (qArr.length > 0 ) { 
			connection.query(q,
				arr,
				function (err, result) {
					if (err) throw err
					let obj = {'uuid': uuid }	
					cb(obj)
			})
		} else {
			let obj = {'uuid': uuid }	
			cb(obj)
		}
	},	

	getAllUserRooms: (res,cb) => {
		connection.query('select * from userRoom ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getUserRoom: (res,uuid,cb) => {
		connection.query('select * from userRoom where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				cb(r)
		})
	},

}

