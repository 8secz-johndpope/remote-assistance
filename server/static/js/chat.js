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
let currentIndex = 0;
let jbScanner;

msgerForm.addEventListener("submit", event => {
  event.preventDefault();

  const msgText = msgerInput.value;
  if (!msgText) return;

  appendMessage(PERSON_NAME, PERSON_IMG, "right", msgText,[]);
  msgerInput.value = "";

  botResponse(msgText);
});

function injectMsg(msg) {
  appendMessage(PERSON_NAME, PERSON_IMG, "right", msg,[]);
  botResponse(msg);
}

function launchRA() {
  $.getJSON(SERVER_API + "createCustomer").then(
      function(customerData) {
        $.getJSON(SERVER_API + "createRoom/"+customerData.uuid).then( 
          function(data) {
              let roomID = data.uuid;
              // Connect to iOS
          })
      })
}

function launchEmail(msg) { 
  let body = "\n\nConversation archive copied below.\n\n---\n\n"
  body += JSON.stringify(convArchive);
  body = encodeURIComponent(body);
  window.location.href = "mailto:" + msg + "?subject=Device+issue&body="+body;
}

function launchPhoneCall(msg) {
  window.location.href = "tel:" + msg;
}

function getButtonHTML(botResponseArr) {
  const html = "";
  for (let i = 0; i < botResponseArr.length; i++) {
    let action = botResponseArr[i].action;
    switch (botResponseArr[i].type) {
      case "response":
       html += `<button onclick='injectMsg(${action})'>${action}</button>`;
       break;
      case "barcode":
       html += `<button onclick='launchQRScanner()'><span class="glyphicon glyphicon-qrcode"></span></button>`;
       break;
      case "ra":
       html += `<button onclick='launchRA()'><span class="glyphicon glyphicon-user"></span></button>`;
       break;
      case "email":
       html += `<button onclick='launchEmail(${action})'><span class="glyphicon glyphicon-envelope"></span></button>`;
       break;
      case "phone":
       html += `<button onclick='launchPhoneCall(${action})'><span class="glyphicon glyphicon-earphone"></span></button>`;
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

function saveResponse(q,r) {
  let res = new Object();
  res.question = q; res.response = r;
  convArchive.push(res);
}

function botResponse(msgText) {
  //const r = random(0, BOT_MSGS.length - 1);
  let botMsgText = BOT_MSG_UNKNOWN;
  let botResponseArr = [];

  let msgTextInt = parseInt(msgText);
  if (isNaN(msgTextInt)) {
    saveResponse(CHAT_TREE.responses[currentIndex].question,msgText);
    currentIndex = CHAT_TREE.responses[currentIndex].next[1];
  } else {
    for (let i = 0; i < CHAT_TREE.responses[currentIndex].length; i++) {
     if (msgTextInt == CHAT_TREE.responses[currentIndex].next[i]) {
      saveResponse(CHAT_TREE.responses[currentIndex].question,i+1);
      currentIndex = CHAT_TREE.responses[currentIndex].next[i];
     }
    }
  }  

  for (let i = 0; i < CHAT_TREE.responses[currentIndex].next; i++) {
    let pReg = /\+[0-9]+/;
    let eReg = /.+?@.+?\..+/;
    let t = CHAT_TREE.responses[currentIndex].next[i];
    let nextBtn = new Object();
    if (isNaN(msgTextInt)) {
      if (t == "barcode") {
        nextBtn.type = "barcode"; nextBtn.action = CHAT_TREE.responses[currentIndex].next[i+1];
        botResponseArr.append(nextBtn);
        break;
      } else {
        if (t == "ra") {
          nextBtn.type = "ra"; nextBtn.action = "";
        } else if (t.match(eReg)) {
          nextBtn.type = "email"; nextBtn.action = t;
        } else if (t.match(pReg)) {
          nextBtn.type = "phone"; nextBtn.action = t;
        }
        botResponseArr.append(nextBtn);
      }
    } else {
      nextBtn.type = "response"; nextBtn.action = t;
      botResponseArr.append(nextBtn);
    }
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
  console.log(scannedText);
  $('#myModal').modal('hide');
  jbScanner.stopScanning();
  //jbScanner.removeFrom( htmlElement )
  appendMessage(PERSON_NAME, PERSON_IMG, "right", msg);
  botResponse(msg);
}

//this function will be called when JsQRScanner is ready to use
function JsQRScannerReady()
{
    jbScanner = new JsQRScanner(onQRCodeScanned);
    jbScanner.setSnapImageMaxSize(300);
    scannerParentElement = document.getElementById("scanner");
    //jbScanner.appendTo(scannerParentElement);
    //console.log(jbScanner);
    //launchQRScanner();
}

function launchQRScanner() {
  $('#myModal').modal('show');
}

appendMessage(BOT_NAME, BOT_IMG, "left", "Hello, how may I help you today?", []);
