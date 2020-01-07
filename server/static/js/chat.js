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

const CHAT_TREE = JSON.parse(CHAT_TREE_JSON);

let convArchive = []; 
let currentIndex = 1;
let jbScanner;

msgerForm.addEventListener("submit", event => {
  event.preventDefault();

  const msgText = msgerInput.value;
  if (!msgText) return;

  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgText,[]);
  msgerInput.value = "";

  botResponse(msgText);
});

function injectMsg(msg,msgLabel) {
  console.log(msg,msgLabel);
  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgLabel,[]);
  botResponse(msg,msgLabel);
}

function launchRA() {
  $.getJSON(SERVER_API + "createCustomer").then(
    function(customerData) {
      $.getJSON(SERVER_API + "createRoom").then( 
        function(roomData) {
          $.getJSON(SERVER_API + "addUserToRoom/"+roomData.room_uuid+"/"+customerData.uuid).then( 
            function(data) {
              console.log("Connecting user",customerData.uuid,"to room", roomData.room_uuid);
              // Connect to iOS
          })
      })
  })
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

function getButtonHTML(botResponseArr) {
  let html = "";
  for (let i = 0; i < botResponseArr.length; i++) {
    let action = botResponseArr[i].action;
    switch (botResponseArr[i].type) {
      case "response":
       let actionLabel = botResponseArr[i].actionLabel;
       html += `<button class="btn btn-primary" style="margin-top: 10px" onclick='injectMsg(${action},\"${actionLabel}\")'>${actionLabel}</button> `;
       break;
      case "barcode":
       html += `<button class="btn btn-warning" style="margin-top: 10px" onclick='launchQRScanner(${action})'><span class="fa fa-qrcode fa-2x"></span></button> `;
       break;
      case "ra":
       html += `<button class="btn btn-danger" style="margin-top: 10px" onclick='launchRA()'><span class="fa fa-user fa-2x"></span></button> `;
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
}

function saveResponse(q,r,rl) {
  let res = new Object();
  res.question = q; res.response = r; res.responseLabel = rl;
  convArchive.push(res);
}

function botResponse(msgText,msgLabel="") {
  //const r = random(0, BOT_MSGS.length - 1);
  let botMsgText = BOT_MSG_UNKNOWN;
  let botResponseArr = [];

  let msgTextInt = parseInt(msgText);
  if (isNaN(msgTextInt)) {
    saveResponse(CHAT_TREE.responses[currentIndex-1].q,msgText,msgLabel);
    currentIndex = CHAT_TREE.responses[currentIndex-1].next[1];
  } else if (msgText == 0) { 
      currentIndex = 1;
  } else {
    for (let i = 0; i < CHAT_TREE.responses[currentIndex-1].next.length; i++) {
     if ((CHAT_TREE.responses[currentIndex-1].next.length == 1) || (msgTextInt == CHAT_TREE.responses[currentIndex-1].next[i])) {
      //console.log(msgTextInt);
      saveResponse(CHAT_TREE.responses[currentIndex-1].q,msgText,msgLabel);
      currentIndex = CHAT_TREE.responses[currentIndex-1].next[i];
     }
    }
  }  

  botMsgText = CHAT_TREE.responses[currentIndex-1].q;

  for (let i = 0; i < CHAT_TREE.responses[currentIndex-1].next.length; i++) {
    let pReg = /\+[0-9]+/;
    let eReg = /.+?@.+?\..+/;
    let t = CHAT_TREE.responses[currentIndex-1].next[i].toString();
    let nextBtn = new Object();
    if (t == "barcode") {
        nextBtn.type = "barcode"; 
        nextBtn.action = CHAT_TREE.responses[currentIndex-1].next[i+1];
        botResponseArr.push(nextBtn);
        break;
    } else if (t == "ra") {
          nextBtn.type = "ra"; nextBtn.action = "";
    } else if (t.match(eReg)) {
          nextBtn.type = "email"; nextBtn.action = t;
    } else if (t.match(pReg)) {
          console.log("Phone");
          nextBtn.type = "phone"; nextBtn.action = t;
    } else {
      let tL = CHAT_TREE.responses[currentIndex-1].nextLabels ? CHAT_TREE.responses[currentIndex-1].nextLabels[i] : t;
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

function formatDate(date) {
  const h = "0" + date.getHours();
  const m = "0" + date.getMinutes();

  return `${h.slice(-2)}:${m.slice(-2)}`;
}

function random(min, max) {
  return Math.floor(Math.random() * (max - min) + min);
}

function onQRCodeScanned(scannedText)
{
  let scannerParentElement = document.getElementById("scanner");
  $('#myModal').modal('hide');
  jbScanner.stopScanning();
  jbScanner.removeFrom( scannerParentElement )
  injectMsg(jbScanner.action,scannedText);
}

//this function will be called when JsQRScanner is ready to use
function JsQRScannerReady()
{
    jbScanner = new JsQRScanner(onQRCodeScanned);
    jbScanner.setSnapImageMaxSize(300);
    console.log("QR scanner ready");
    //console.log(jbScanner);
    //launchQRScanner();
}

function launchQRScanner(action) {
  let scannerParentElement = document.getElementById("scanner");
  jbScanner.appendTo(scannerParentElement);
  jbScanner.action = action;
  $('#myModal').modal('show');
}

botResponse(0);
//appendMessage(BOT_NAME, BOT_IMG, "left", "Hello, how may I help you today?", []);
