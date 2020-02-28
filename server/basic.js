/*!
 * Remote Asistance/ACE
 * Copyright(c) 2020 FX Palo Lato Labs, Inc.
 * License: contact ace@fxpal.com
 */

const config = require('config');
const express = require('express');

var router = express.Router()

// The "basic" implementation for remote assistance

// Basic room home page
router.get('/', function (req, res) {
    res.render('index.html', { roomid: 'basic' });
});

// Expert page home page
router.get('/expert', function (req, res) {
    res.render('expert_basic.html', { roomid: 'basic' });
});

// Customer     
router.get('/customer', function (req, res) {
    res.render('customer.html', { roomid: 'basic' });
});

module.exports = router;