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
const DEFAULT_RESPONSE = "Continue";

const CTJ = CHAT_TREE_JSON.replace(/(\r\n|\n|\r)/gm, "")
//console.log(CTJ);
let responses = []

let convArchive = {}; convArchive.responses = []; 
let currentIndex = 1;
let jbScanner;
let savedAction;
let savedUrl;
let savedOptions;
let printerDetails;
let ocrConfirmText = "";
let ocrConfirm = false;

msgerForm.addEventListener("submit", event => {
  event.preventDefault();

  const msgText = msgerInput.value;
  if (!msgText) return;

  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgText,[]);
  msgerInput.value = "";

   console.log(ocrConfirm);

  if (ocrConfirm) {
    injectMsg(savedAction,msgText,false);
  } else {
    //botResponse(msgText);    
  }
});

function injectMsg(msg,msgLabel,userResponse=true) {
  //console.log(msg,msgLabel);
  let msgLabelO = msgLabel;
  let validTxt = true;

  if (ocrConfirm) {
    msgLabelO += " is correct";
  }

  if (userResponse && (msgLabelO.length > 0)) {
     appendMessage(PERSON_NAME, PERSON_IMG, "right", msgLabelO,[]);          
  } else if (ocrConfirm) {     
      validTxt = false;
      for (let i=0; i < savedOptions.data.length; i++) {
        if ( (savedOptions.data[i].name && savedOptions.data[i].name==msgLabel) ||
             ((savedOptions.data[i].code && savedOptions.data[i].code==msgLabel)) ) {
            validTxt = true;
          break;
        }
      }
  }

  saveResponse(responses[currentIndex],msg,msgLabel);

  if (!validTxt) {
    let botResponseArr = []; let nextBtn = new Object();
    nextBtn.type = "ra"; nextBtn.action = ""; nextBtn.actionLabel = "";
    let botMsgText = "We did not find that in our database. Please connect to a remote assistant.";
    botResponseArr.push(nextBtn);
    appendMessage(BOT_NAME, BOT_IMG, "left", botMsgText, botResponseArr);
  } else {
    console.log(msg);
    botResponse(msg+"",msgLabel);    
  } 
  ocrConfirm = false; ocrConfirmText = "";
}

function launchLink(url,action) {
  savedAction = action;
  //setTimeout(injectMsg,1000,savedAction,"(viewing link)");
  console.log(url);
  window.open(url, '_blank');
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
    let actionLabel = botResponseArr[i].actionLabel;
    switch (botResponseArr[i].type) {
      case "response":
       html += `<button class="btn btn-primary" style="margin-top: 10px; margin-right: 25px" onclick='injectMsg(\"${action}\",\"\")'>${actionLabel}</button> `;
       break;
      case "ocrResponse":
       html += `<button class="btn btn-primary" style="margin-top: 10px; margin-right: 25px" onclick='injectMsg(\"${action}\",\"${actionLabel}\")'>Continue</button> `;
       break;
      case "barcode":
       html += `<img style="margin-top: 10px" onclick='launchQRScanner(\"${action}\")' width=64 height=64 src='/static/images/blueSCAN-QR_64.png'></img>`;
       break;
      case "link":
       if ( (url.toLowerCase().includes("youtu.be")) || (url.toLowerCase().includes("youtube")) || (url.toLowerCase().includes("vimeo")) ) {
         html += `<img style="margin-top: 10px" onclick='launchLink(\"${url}\",\"${action}\")' width=64 height=64 src='/static/images/goldCONTENT-video_64.png'></img> `;
       } else {
         html += `<img style="margin-top: 10px" onclick='launchLink(\"${url}\",\"${action}\")' width=64 height=64 src='/static/images/ goldCONTENT-web_64.png'></img> `;        
       }
       html += `<div style="margin-top: 20px"><button class="btn btn-primary" style="margin-top: 10px; margin-right: 25px" onclick='injectMsg(\"${action}\",\"\")'>${DEFAULT_RESPONSE}</button></div>`;
       break;
      case "ra":
       html += `<img style="margin-top: 10px; margin-right: 10px" onclick='launchRA()' width=64 height=64 src='/static/images/blueCHAT-AR_64.png'></img> `;
       break;
      case "showARScene":
       html += `<img style="margin-top: 10px" onclick='launchAR3D(\"${action}\")' width=64 height=64 src='/static/images/blueSCAN-AR_64.png'></img> `;
       break;
      case "showARVideo":
       html += `<img style="margin-top: 10px" onclick='launchARVideo(\"${action}\")' width=64 height=64 src='/static/images/blueSCAN-AR_64.png'></img> `;
       break;
      case "scanText":
       ocrConfirm = true;
       savedAction = action;
       html += `<img style="margin-top: 10px" onclick='launchOCRScanner(\"${action}\",\"${url}\")' width=64 height=64 src='/static/images/blueSCAN-OCR_64.png'>`;
       break;
      case "email":
       html += `<button class="btn btn-warning" style="margin-top: 10px" onclick='launchEmail(\"${action}\")'><span class="fa fa-envelope fa-2x"></span></button> `;
       break;
      case "phone":
       html += `<img style="margin-top: 10px" onclick='launchPhoneCall(\"${action}\")' width=64 height=64 src='/static/images/blueCHAT-phone_64.png'></img>`;
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

function botResponse(msgText,msgLabel="",q="") {
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

  if (q.length == 0) {
    botMsgText = parseQuestion(responses[currentIndex].q);     
  } else {
    botMsgText = q;
  }

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
        setSavedOptions(nextBtn.url);
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
        nextBtn.actionLabel = DEFAULT_RESPONSE;
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

async function setSavedOptions(url) {
  savedOptions = await getURL(url);
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
  savedAction = action; savedUrl = url;
  // Launch native text scanner
  if (runningNative()) {
      window.webkit.messageHandlers.launchOCRScanner.postMessage(
      { 
          options: savedOptions
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
  appendMessage(PERSON_NAME, PERSON_IMG, "right", "...",[]);
  ocrConfirmText = scannedText; 
  if (!runningNative()) {
    //
  }
  let botResponseArr = []; let nextBtn = new Object();
  let botMsgText = "";
  if (scannedText.length == 0) {
    botMsgText = "I am sorry I did not find any matches. Please type in the text manually or scan again.";
    nextBtn.type = "scanText"; nextBtn.action = savedAction; nextBtn.url = savedUrl;
  } else {
    nextBtn.type = "ocrResponse"; nextBtn.action = savedAction; nextBtn.actionLabel = scannedText;
    botMsgText = 'I found: <b>' + scannedText + 
                   '</b>. If that is not correct, please type in the text manually. Otherwise, press...';
  }
  botResponseArr.push(nextBtn);
  appendMessage(BOT_NAME, BOT_IMG, "left", botMsgText, botResponseArr);
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
