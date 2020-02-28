/*!
 * Remote Asistance/ACE
 * Copyright(c) 2020 FX Palo Lato Labs, Inc.
 * License: contact ace@fxpal.com
 */

const os = require('os');
const dns = require('dns');

function reverseLookup(ip) {
	dns.reverse(ip,function(err,domains){
		if(err!=null)	callback(err);

		domains.forEach(function(domain){
			dns.lookup(domain,function(err, address, family){
				console.log(domain,'[',address,']');
				console.log('reverse:',ip==address);
			});
		});
	});
}

function getInterfaces() {
    var ifaces = os.networkInterfaces();

    // ignore loopback
    delete ifaces['lo'];
    var keys = Object.keys(ifaces);
    return keys.map(function(key) {
        var addrs = ifaces[key];
        var ipv4;
        addrs.forEach(function(addr) {
            if (addr.family == 'IPv4') {
                ipv4 = addr;
                addr.name = key;
                return addr;
            }
        });
        return ipv4;
      }).filter(function(addr) {
          return addr != null;
      });
}

function generateRandomId() {
    var text = "";
    var l = 9;
    //var char_list = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    var char_list = "0123456789";
    for(var i=0; i < l; i++) {
        text += char_list.charAt(Math.floor(Math.random() * char_list.length));
    }
    return text;
}

module.exports = {
    getInterfaces,
    generateRandomId
}
