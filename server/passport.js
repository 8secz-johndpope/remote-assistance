const LocalStrategy   = require('passport-local').Strategy;
const db = require('./db')
const uuid = require('uuid');
const bcrypt = require('bcrypt-nodejs');

module.exports = function(passport) {

    passport.serializeUser(function(user, done) {
		done(null, user.uuid);
    });

    passport.deserializeUser(function(uuid, done) {
		db.getConnection().query("select * from user where uuid = ?",
            [
             uuid
            ],
            function(err,rows){	
			done(err, rows[0]);
		});
    });
	
    passport.use('local-signup', new LocalStrategy({
        usernameField : 'email',
        passwordField : 'password',
        passReqToCallback : true // allows us to pass back the entire request to the callback
    },
    function(req, email, password, done) {
        connection.query("select * from user where email = ?",
        [
            email
        ], 
        function(err,rows){
			if (err)
                return done(err);
			 if (rows.length) {
                return done(null, false, req.flash('signupMessage', 'That email is already taken.'));
            } else {
                let u = new Object();
				
				u.email = email
			    u.uuid  = uuid.v4()

                bcrypt.genSalt(10, function(err, salt) {
                    if (err) return next(err)
                    bcrypt.hash(u.password, salt, function(err, hash) {
                        if (err) return next(err)
                        u.password = hash
                        connection.query("INSERT INTO users ( email, password, uuid ) values ( ?, ?, ?)",
                            [
                                email,
                                u.password,
                                uuid
                            ]
                            function(err,rows){         
                                return done(null, u)
                            })
                        })
                  })
            }	
		})
    }))

    passport.use('local-login', new LocalStrategy({
        usernameField : 'email',
        passwordField : 'password',
        passReqToCallback : true // allows us to pass back the entire request to the callback
    },
    function(req, email, password, done) { // callback with email and password from our form

         connection.query("select * from user where email = ?",
            [
            email
            ]
         ,function(err,rows){
			if (err)
                return done(err)
			 if (!rows.length) {
                return done(null, false, req.flash('loginMessage', 'No user found.'))
            } 
			
            bcrypt.compare(password, rows[0].password, function(err, res) {
              if (err) return cb(err)
              if (res === false) {
               return done(null, false, req.flash('loginMessage', 'Oops! Wrong password.'))
              } else {
               return done(null, rows[0])
              }
            })
	
		})

    }))

}