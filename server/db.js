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

	createUser: (res,cb) => {
		let uuid = util.generateRandomId();
		connection.query('insert into user(uuid,type) values(?,?)',
			[
				uuid,
				"customer"
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

	createRoom: (res,user_uuid,cb) => {
		let uuid = util.generateRandomId();
		let now = new Date() / 1000;
		connection.query('insert into room(uuid,user_uuid,time_created) values(?,?,?)',
			[
				uuid,
				user_uuid,
				now
			],
			function (err, rows, fields) {
				if (err) throw err
				let obj = {'uuid': uuid }	
				cb(obj)
		})
	}


}

