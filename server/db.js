const mysql = require('mysql')
const connection = mysql.createConnection({
		host: "harddb.fxpal.net",
		user: "ace",
		password: "hmqN3kCmawG33whCnEGy65PUi",
		database: "ace"
})	
connection.connect(function(err) {
	if (err) throw err
	
});

module.exports = {
	
	getRoom: (res,uuid) => {
		connection.query('select * from room where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				//res.end(JSON.stringify(objs));
				res.json(rows)
		})		
	},

	getClip: (res,uuid) => {
		connection.query('select * from clip where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				//res.end(JSON.stringify(objs));
				res.json(rows)
		})		
	},

	getUser: (res,uuid) => {
		connection.query('select * from user where uuid = ?',
			[
				uuid
			],
			function (err, rows, fields) {
				if (err) throw err
				//res.end(JSON.stringify(objs));
				res.json(rows)
		})
	}

}

