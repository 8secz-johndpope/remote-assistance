const mysql = require('mysql')
const config = require('config');
const parseDbUrl = require("parse-database-url");
const databaseConfig = parseDbUrl(config.databaseUrl);
const util = require('./util');

// load the database info from config/...
const connection = mysql.createConnection(databaseConfig);
connection.connect(function(err) {
	if (err) throw err
	console.log(`Connected to mysql: ${databaseConfig.host}/${databaseConfig.database}`);
});

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
				cb(rows)
		})		
	},

	getActiveRooms: (res,cb) => {
		connection.query('SELECT roomUser.room_uuid,user.type FROM roomUser,user where roomUser.state = 1 and user.uuid = roomUser.user_uuid',
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
						let obj = { room_uuid: ru, experts: 0, customers: 0 };
						ret.unshift(obj);
						index = 0;
					}
					if (t == "expert") { ret[index].experts = ret[index].experts+1; ret.push(ret.splice(index, 1)[0]); }
					if (t == "customer") { ret[index].customers = ret[index].customers+1; }
				}
				cb(ret);
		})		
	},

	getClip: (res,uuid,cb) => {
		connection.query('select * from clip where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				cb(rows)
		})		
	},

	getClips: (res,marker_uuid,cb) => {
		connection.query('select clip.* from clip join clipMarker on clipMarker.clip_uuid=clip.uuid where clipMarker.marker_uuid = ?',
			[
				marker_uuid
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
				cb(rows)
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
						let obj = {'uuid_uuid': user_uuid, "room_uuid": room_uuid }	
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
							let obj = {'uuid_uuid': user_uuid, "room_uuid": room_uuid }	
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
				let obj = {'uuid_uuid': user_uuid, "room_uuid": room_uuid }	
				cb(obj)
		})
	}

}

