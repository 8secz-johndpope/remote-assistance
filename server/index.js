var express = require('express');
var app = express();

app.get('/', function(req, res){
   res.send("Hello world!");
});

console.log('Server runnning on localhost:3000')
app.listen(3000);
