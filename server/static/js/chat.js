const msgerForm = get(".msger-inputarea");
const msgerInput = get(".msger-input");
const msgerChat = get(".msger-chat");

const BOT_IMG = "chatBot.png";
const PERSON_IMG = "user.png";
const BOT_NAME = "DC Bot";
const PERSON_NAME = " ";
const BOT_DELAY = 500;
const BOT_MSG_UNKNOWN = "I'm sorry, I didn't understand your response.";
const SERVER_API = "/api/";
const NATIVE_UA = "ace";

const CTJ = CHAT_TREE_JSON.replace(/(\r\n|\n|\r)/gm, "")
//console.log(CTJ);
let responses = []

let convArchive = {}; convArchive.responses = []; 
let currentIndex = 1;
let jbScanner;
let savedAction;
let printerDetails;

msgerForm.addEventListener("submit", event => {
  event.preventDefault();

  const msgText = msgerInput.value;
  if (!msgText) return;

  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgText,[]);
  msgerInput.value = "";

  botResponse(msgText);
});

function injectMsg(msg,msgLabel) {
  //console.log(msg,msgLabel);
  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgLabel,[]);
  saveResponse(responses[currentIndex],msg,msgLabel);
  botResponse(msg,msgLabel);
}

function launchLink(url,action) {
  savedAction = action;
  setTimeout(injectMsg,1000,savedAction,"(viewing link)");
  window.location = url;
}

function launchEmail(msg) { 
  let body = "\n\nConversation archive copied below.\n\n---\n\n"
  body += JSON.stringify(convArchive);
  body = encodeURIComponent(body);
  window.location.href = "mailto:" + msg + "?subject=Device%20issue&body="+body;
}

function launchPhoneCall(msg) {
  window.location.href = "tel:" + msg;
}

function validURL(str) {
  var pattern = new RegExp('^(http(s)?:\\/\\/)?'+ // protocol
    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ // domain name
    '((\\d{1,3}\\.){3}\\d{1,3}))'+ // OR ip (v4) address
    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ // port and path
    '(\\?[;&a-z\\d%_.~+=-]*)?'+ // query string
    '(\\#[-a-z\\d_]*)?$','i'); // fragment locator
  return !!pattern.test(str);
}

function getButtonHTML(botResponseArr) {
  let html = "";
  for (let i = 0; i < botResponseArr.length; i++) {
    let url = botResponseArr[i].url; 
    let action = botResponseArr[i].action;
    switch (botResponseArr[i].type) {
      case "response":
       let actionLabel = botResponseArr[i].actionLabel;
       html += `<button class="btn btn-primary" style="margin-top: 10px; margin-right: 25px" onclick='injectMsg(\"${action}\",\"${actionLabel}\")'>${actionLabel}</button> `;
       break;
      case "barcode":
       html += `<button class="btn btn-warning" style="margin-top: 10px" onclick='launchQRScanner(\"${action}\")'><span class="fa fa-qrcode fa-2x"></span></button> `;
       break;
      case "link":
       html += `<button class="btn btn-warning" style="margin-top: 10px" onclick='launchLink(\"${url}\",\"${action}\")'><span class="fa fa-link fa-2x"></span></button> `;
       break;
      case "ra":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchRA()'><span class="fa fa-user fa-2x"></span></button> `;
       break;
      case "showARScene":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchAR3D(\"${action}\")'><span class="fa fa-camera fa-2x"></span></button> `;
       break;
      case "showARVideo":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchARVideo(\"${action}\")'><span class="fa fa-camera fa-2x"></span></button> `;
       break;
      case "scanText":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchOCRScanner(\"${action}\",\"${url}\")'><span class="fa fa-camera fa-2x"></span></button> `;
       break;
      case "email":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchEmail(\"${action}\")'><span class="fa fa-envelope fa-2x"></span></button> `;
       break;
      case "phone":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchPhoneCall(\"${action}\")'><span class="fa fa-phone fa-2x"></span></button> `;
       break;
     }
  }
  return html;
}

function appendMessage(name, img, side, text, botResponseArr) {
  const buttonHTML = getButtonHTML(botResponseArr)

  const msgHTML = `
    <div class="msg ${side}-msg">
      <div class="msg-img" style="background-image: url(${img})"></div>

      <div class="msg-bubble">
        <div class="msg-info">
          <div class="msg-info-name">${name}</div>
          <div class="msg-info-time">${formatDate(new Date())}</div>
        </div>

        <div class="msg-text">${text}</div>
        <div>${buttonHTML}</div>
      </div>
    </div>
  `;

  msgerChat.insertAdjacentHTML("beforeend", msgHTML);
  msgerChat.scrollTop += 500;
  window.scrollTo(0,document.body.scrollHeight);
  window.scrollTo(0,document.querySelector(".msger-chat").scrollHeight);

}

function saveResponse(item,r,rl) {
  let res = new Object();
  res.question = item.q; res.response = r; res.responseLabel = rl;
  if (item.setVar) { 
    let sv = item.setVar; convArchive[sv] = rl; 
    if (sv == "printerName") {
      getPrinterDetails(rl);
    }
  }
  convArchive.responses.push(res);
  //console.log(JSON.stringify(convArchive));
}

function parseQuestion(q) {
  let regexp = /\{\{([^{}]*)\}\}/g;
  let arr = [...q.matchAll(regexp)];
  for (let i=0; i<arr.length;i++) {
    let replaceWith = "";
    let toReplaceRaw = arr[i][0];
    let toReplace = arr[i][1];
    //console.log(toReplace + " " + convArchive[toReplace]);
    if (toReplace =="userEmail") {
      // DEBUG
      replaceWith = "test@fxpal.com";
      // DEBUG
    } else if (toReplace =="partList") {
      replaceWith = printerDetails.data.partsList;
    } else if (toReplace =="deviceType") {
      replaceWith = deviceType;
      convArchive["deviceType"] = replaceWith; // When to set this?
    } else if (toReplace in convArchive) {
      replaceWith = convArchive[toReplace];
    }
    q = q.replace(toReplaceRaw,replaceWith);
  }
  return q;
}

function botResponse(msgText,msgLabel="") {
  //const r = random(0, BOT_MSGS.length - 1);
  let botMsgText = BOT_MSG_UNKNOWN;
  let botResponseArr = [];

  let msgTextInt = parseInt(msgText);
  //console.log(msgText + " " + msgTextInt);

  const regex = /[0-9]+m[0-9]+m[0-9]+/g;
  const found = msgText.match(regex);
  //console.log(msgText + " " + regex);
  if ( found !== null ) {
    // Example: "next": ["15m16m17"],
    //          is parsed as Android,iOS,other 
    const tmp = found[0].split("m");
    if (convArchive["deviceType"] == "Android") {
      currentIndex = parseInt(tmp[0]);
    } else if (convArchive["deviceType"] == "iOS") {
      currentIndex = parseInt(tmp[1]);
    } else {
      currentIndex = parseInt(tmp[2]);
    console.log(found[0] + " " + tmp[2]);
    }
  } else if (isNaN(msgTextInt)) {
      currentIndex = responses[currentIndex].next[1];      
  } else if (msgText == 0) { 
      currentIndex = 1;
  } else if (responses[currentIndex].next.length  == 0) {
    return;
  } else {
    for (let i = 0; i < responses[currentIndex].next.length; i++) {
     if ((responses[currentIndex].next.length == 1) || (msgTextInt == responses[currentIndex].next[i])) {
      //console.log(msgTextInt);
      currentIndex = responses[currentIndex].next[i];
     }
    }
  }  

  botMsgText = parseQuestion(responses[currentIndex].q); 

  // + " " + runningNative();

  for (let i = 0; i < responses[currentIndex].next.length; i++) {
    let pReg = /\+[0-9]+/;
    let eReg = /.+?@.+?\..+/;
    let t = responses[currentIndex].next[i].toString();
    let nextBtn = new Object();
    if (t == "barcode") {
        nextBtn.type = "barcode"; 
        nextBtn.action = responses[currentIndex].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else if (t == "scanText") {
        nextBtn.type = "scanText"; 
        nextBtn.url = responses[currentIndex].url;
        nextBtn.action = responses[currentIndex].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else if (t == "showARScene") {
        nextBtn.type = "showARScene"; 
        nextBtn.action = responses[currentIndex].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else if (t == "showARVideo") {
        nextBtn.type = "showARVideo"; 
        nextBtn.action = responses[currentIndex].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else if (t == "ra") {
          nextBtn.type = "ra"; nextBtn.action = "";
    } else if (t.match(eReg)) {
          nextBtn.type = "email"; nextBtn.action = t;
    } else if (t.match(pReg)) {
          nextBtn.type = "phone"; nextBtn.action = t;
    } else if (validURL(t)) {
        nextBtn.type = "link"; 
        nextBtn.url = t;
        nextBtn.action = responses[currentIndex].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else {
      let tL = responses[currentIndex].nextLabels ? responses[currentIndex].nextLabels[i] : t;
      nextBtn.type = "response"; nextBtn.action = t; nextBtn.actionLabel = tL;
    }
    botResponseArr.push(nextBtn);
  }

  setTimeout(() => {
    appendMessage(BOT_NAME, BOT_IMG, "left", botMsgText, botResponseArr);
  }, BOT_DELAY);
}

// Utils
function get(selector, root = document) {
  return root.querySelector(selector);
}

function getURL(url) {
  url = encodeURI(SERVER_API + url); 
  console.log(url);
  return $.getJSON(url)
    .then(function(data){
      return {
        data
    }
  });
}

function formatDate(date) {
  const h = "0" + date.getHours();
  const m = "0" + date.getMinutes();

  return `${h.slice(-2)}:${m.slice(-2)}`;
}

function random(min, max) {
  return Math.floor(Math.random() * (max - min) + min);
}

// Launchers (connect to iOS native)
function launchRA() {
  localStorage.setItem('convArchive',JSON.stringify(convArchive));
  $.post(SERVER_API + "room").then( 
    function(roomData) {
      if (runningNative()) {
        window.webkit.messageHandlers.launchRA.postMessage(
          { 
            user_uuid: user_uuid,
            room_uuid: roomData.room_uuid,
            archive: convArchive //JSON.stringify(convArchive)
          });                
      } else {
          window.location.href = "/" + roomData.uuid + "/customer"; 
      }
    })
}

function launchAR3D(action) {
  savedAction = action;
  if (runningNative()) {
      console.log("Launching AR3D...")
      window.webkit.messageHandlers.launchAR3D.postMessage(
      { 
      }); 
      } else {
          injectMsg(savedAction,"If I were on a mobile device I could show you how with AR!");
      }
}

function onAR3DResponse()
{
  if (!runningNative()) {
    //console.log("Back from AR 3D scene")
  }
  injectMsg(savedAction,"OK");
}

function launchARVideo(action) {
  savedAction = action;
  if (runningNative()) {
      console.log("Launching ARVideo...")
      window.webkit.messageHandlers.launchARVideo.postMessage(
      { 
      }); 
      } else {
          injectMsg(savedAction,"If I were on a mobile device I could show you how with AR!");
      }
}

function onARVideoResponse()
{
  if (!runningNative()) {
    //console.log("Back from AR video scene")
  }
  injectMsg(savedAction,"OK");
}

async function launchOCRScanner(action,url) {
  savedAction = action;
  // Launch native text scanner
  let options = await getURL(url);
  console.log(options);
  if (runningNative()) {
      window.webkit.messageHandlers.launchOCRScanner.postMessage(
      { 
          options: options
      }); 
  } else {
    // DEBUG
    let scannedText = "";
    if ( (action == 5) || (action == 23) ) {
      scannedText = "ApeosPort-VII C7773";    
    } else if (action == 7) {
      scannedText = "32342";
    }
    injectMsg(savedAction,scannedText);
    // DEBUG
    }
}

async function getPrinterDetails(printerName) {
    let url = "printerName/" + printerName
    printerDetails = await getURL(url);
}

function onOCRScanned(scannedText)
{
  if (!runningNative()) {
    //
  }
  injectMsg(savedAction,scannedText);
}

function launchQRScanner(action) {
    savedAction = action;
    if (runningNative()) {
      window.webkit.messageHandlers.launchQRScanner.postMessage(
      { 
      });                
    } else {
      let scannerParentElement = document.getElementById("scanner");
      jbScanner.appendTo(scannerParentElement);
      $('#myModal').modal('show');
    }
}

function onQRCodeScanned(scannedText)
{
  if (!runningNative()) {
    closeJSQRScanner();
  }
  injectMsg(savedAction,scannedText);
}

function closeJSQRScanner() {
    let scannerParentElement = document.getElementById("scanner");
    $('#myModal').modal('hide');
    jbScanner.stopScanning();
    jbScanner.removeFrom( scannerParentElement )      
}

//this function will be called when JsQRScanner is ready to use
function JsQRScannerReady()
{
    jbScanner = new JsQRScanner(onQRCodeScanned);
    jbScanner.setSnapImageMaxSize(300);
    //console.log("QR scanner ready");
    //console.log(jbScanner);
    //launchQRScanner();
}


function runningNative() {
  let n = false;
  if (window.webkit && window.webkit.messageHandlers) {
    n = true;
  } 
  return n;
}

function loadUser() {
  if (user_uuid === undefined) {
    $.post(SERVER_API + "user", {"type": "customer"}).then( 
      function(data) {
        console.log('Created customer', data);
        Cookies.set('customer_uuid', data.uuid);
      }
    )
  }
}

// Determine the mobile operating system.
// Returns one of 'iOS', 'Android', 'Windows Phone', or 'desktop'.
function getMobileOperatingSystem() {
  var userAgent = navigator.userAgent || navigator.vendor || window.opera;

      // Windows Phone must come first because its UA also contains "Android"
    if (/windows phone/i.test(userAgent)) {
        return "Windows Phone";
    }

    if (/android/i.test(userAgent)) {
        return "Android";
    }

    // iOS detection from: http://stackoverflow.com/a/9039885/177710
    if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
        return "iOS";
    }

    return "desktop";
}

function fillResponses() {
  const ct = JSON.parse(CTJ);
  for (let i=0;i<ct.responses.length;i++) {
    let id = ct.responses[i].id;
    responses[id] = ct.responses[i];
  }
}

fillResponses();
var deviceType = getMobileOperatingSystem();
let user_uuid = Cookies.get('customer_uuid');
loadUser();
botResponse("0");
//appendMessage(BOT_NAME, BOT_IMG, "left", "Hello, how may I help you today?", []);
