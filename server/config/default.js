module.exports = {
    databaseUrl: process.env.DATABASE_URL || 'mysql://ace:hmqN3kCmawG33whCnEGy65PUi@harddb.fxpal.net/ace',
    host: process.env.HOST || '0.0.0.0',
    port: process.env.PORT || 5443,
    wsport: 3000,
    clipLoc: "stor/"
}