const mysql = require('mysql')
const config = require('config');
const parseDbUrl = require("parse-database-url");
const databaseConfig = parseDbUrl(config.databaseUrl);
const util = require('./util');

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
				let r = rows.length > 0 ? rows[0] : {}
				cb(r)
		})		
	},

	getActiveRooms: (res,cb) => {
		connection.query('SELECT roomUser.room_uuid,user.type,room.* FROM roomUser,user,room where roomUser.state = 1 and user.uuid = roomUser.user_uuid and room.uuid = roomUser.room_uuid',
			[				
			],
			function (err, rows, fields) {
				if (err) throw err
				let ret = [];
				for (let i = 0; i < rows.length; i++) {
					let ru = rows[i].room_uuid;
					let t = rows[i].type;
					let index = ret.findIndex(x => x.room_uuid === ru);

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
				cb(rows)
		})		
	},

	getAnchor: (res,uuid,cb) => {
		console.log(uuid)
		connection.query('select * from anchor where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let r = rows.length > 0 ? rows[0] : {}
				cb(r)
		})		
	},

	getAllAnchorsSearch: (res,text,cb) => {
		connection.query('select * from anchor where name like ?',
			[
				'%'+text+'%'
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getAllAnchors: (res,cb) => {
		connection.query('select * from anchor ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
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
				cb(r)
		})		
	},

	getClips: (res,anchor_uuid,room_uuid,cb) => {
		let q = 'select clipAnchor.position_blob,clip.* from clip,clipAnchor where clipAnchor.clip_uuid=clip.uuid and clipAnchor.anchor_uuid = ?'
		let arr = [anchor_uuid]; 
		if (room_uuid) {
			q += ' and clip.room_uuid = ?'
			arr.push(room_uuid)
		}
		connection.query(q,
			arr,
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getAllClips: (res,cb) => {
		connection.query('select * from clip ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
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

	getAllUsers: (res,cb) => {
		connection.query('select * from user ',
			[
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},
	
	addClipAnchor: (res,anchor_uuid,clip_uuid,position_blob,cb) => {
		let uuid = util.generateRandomId();
		connection.query('insert into clipAnchor(anchor_uuid,clip_uuid,position_blob) values(?,?,?)',
			[
				anchor_uuid,
				clip_uuid,
				position_blob
			],
			function (err, result) {
				if (err) throw err
				let obj = {'anchor_uuid': anchor_uuid, 'clip_uuid': clip_uuid}	
				cb(obj)
		})
	},

	addUserToRoom: (res,room_uuid,user_uuid,cb) => {
		let now = new Date() / 1000;
		connection.query('select * from roomUser where user_uuid = ? and room_uuid = ?',
			[
				user_uuid,
				room_uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				if (rows.length > 0) {
					connection.query('update roomUser set time_ping = ?, state = ? where room_uuid = ? and user_uuid = ?',
						[
							now,
							1,
							room_uuid,
							user_uuid
						],
					function (err, rows, fields) {
						if (err) throw err
						let obj = {'user_uuid': user_uuid, "room_uuid": room_uuid }	
						cb(obj)
					})
				} else {
					connection.query('insert into roomUser(room_uuid,user_uuid,time_ping,state) values(?,?,?,?) '
						,
						[
							room_uuid,
							user_uuid,
							now,
							1
						],
						function (err, rows, fields) {
							if (err) throw err
							let obj = {'user_uuid': user_uuid, "room_uuid": room_uuid }	
							cb(obj)
					})					
				}
			})
	},

	removeUserFromRoom: (res,room_uuid,user_uuid,cb) => {
		let now = new Date() / 1000;
		connection.query('update roomUser set time_ping = ?, state = ? where room_uuid = ? and user_uuid = ?',
			[
				now,
				0,
				room_uuid,
				user_uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				let obj = {'uesr_uuid': user_uuid, "room_uuid": room_uuid }	
				cb(obj)
		})
	}

}

