Remote Assistance
=================

The unified Remote Assistance project respository.


How to build client
-------------------

> TODO

How to run server
-----------------

> TODO

Planning
-----------------

### Basic demo
* Target: ~ December 15
* Merge Tele-skele and ScreenAR into single iOS app with WebRTC support
* Create unified web-based WebRTC-based front end capable of supporting: sketch and marker-based annotations, hand pose, and ScreenAR

### Demo with archived clips
* Target: ~ January 15
* Build recording framework
* Integrate step detection into iOS app
* Create DB backend with support for associated metadata (user, etc.)
* Save clip metadata to backend along with user and marker data

### Demo with chat UI for FXA
* Target: ~ January 15
* Build HTML5/Webview chat app
* Implement basic decision tree chat
* Connect one action from chat to iOS AR demo

### Internal test of stable branch
* Target: ~ February 1
* Experiment with live support tasks internal to FXPAL
* Experiment with methods for collation and curation of archived clips

### Lab study of stable branch
* Target: ~ March 1

### Experimentation with other features
* Target: Ongoing in dev branch / external branch
* (What features should go here?)

Chat UI planning details
-----------------
* Implement basic decision tree chat from JSON with key-value pairs
```javascript
ID: #_#_#
Question: “Question text”
Next: [ID,action,ID,…]
```
* Where “action” can be: launch phone call, send email, view video clip, launch AR session
* One open-ended response will ask for a model number (which can be typed or scanned from a QR code using https://github.com/jbialobr/JsQRScanner)



