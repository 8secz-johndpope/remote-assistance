const CHAT_TREE_JSON = `
 { "responses": [ 
    {
    "id": 1,
    "q": "This demonstration will show the following on an ApeosPort-VII C7773:
          <div style='padding:10px 0px 0px 20px'>
          <ul>
          <li>Ordering and installing toner 
          <li>Signing up for a smart remote service (electronic partership [EPBB]) 
          <li>Addressing a fault code 
          <li>Clearing a paper jam 
          <li>Install a print driver
          </ul></div>
          ",
    "next": [2],
    "nextLabels": ["Continue"]
    },
    {
    "id": 2,
    "q": "Hi! Welcome to the Digital Companion App! I'm here to help you and I'm always available.",
    "next": [3],
    "nextLabels": ["Continue"]
    },
    {
    "id": 3,
    "q": "What do you want help with?",
    "next": [4,22,11],
    "nextLabels": ["Fix my printer","I need to replace my printer toner","Speak to someone"]
    },
    {
    "id": 4,
    "q": "Sounds good. Now we need to know your printer model. Please press the button below then frame your device's model name in the camera window.",
    "next": ["scanText",5],
    "url": "printerName",
    "setVar":"printerName"
    },
    {
    "id": 5,
    "q": "Great! You've got a <b>{{printerName}}</b>.
        <a href=\\"/static/images/printers/{{printerName}}.jpg\\" target=\\"_blank\\">
        <img class=\\"img-thumbnail\\" src=\\"/static/images/printers/{{printerName}}.jpg\\" />
        </a>
        Do you want to...",
    "next": [6,12,14],
    "nextLabels": ["Address a fault code","Clear a paper jam","Install a print driver"]
    },
    {
    "id": 6,
    "q": "Sorry to hear that your <b>{{printerName}}</b> has faulted. So we can help you best, please scan your fault code.",
    "next": ["scanText",7],
    "url": "errorCode",
    "setVar":"errorCode"
    },
    {
    "id": 7,
    "q": "Error <b>{{errorCode}}</b>. Got it. Please <b><a href=\\"http://m1-onlinesupport.fujixerox.com/driver_downloads/OTS/AP7C7773/OTS_Solution16195_EN.html\\" target=\\"_blank\\">read this document</a></b> or check out this video:
    <p class=\\"mt-4\\">
    <strong>How To Perform a Combined Calibration -Apeosport/DocuCentre VII C6673 -EN</strong>
    <a href=\\"https://youtu.be/kmNdi8S4Utg\\" target=\\"_blank\\">
    <img class=\\"img-thumbnail\\" src=\\"http://i3.ytimg.com/vi/kmNdi8S4Utg/hqdefault.jpg\\" />
    </a>
    </p>
    ",
    "next": ["https://youtu.be/kmNdi8S4Utg",8]
    },
    {
    "id": 8,
    "q": "Did that fix the problem?",
    "next": [9,10],
    "nextLabels": ["Yes","No"]
    },
    {
    "id": 9,
    "q": "Great, bye!",
    "next": []
    },
    {
    "id": 10,
    "q": "Sorry about that. Please <b><a href=https://onlinesupport.fujixerox.com/processDriverForm.do?ctry_code=AU&lang_code=en&d_lang=en&corp_pid=AP7C7773&rts=null&model=ApeosPort-VII+C7773&type_id=7&oslist=Windows+10+64bit&lang_list=en target=_blank>visit our online FAQ</a></b>, <b><a href=http://m1-onlinesupport.fujixerox.com/driver_downloads/OTS/OTS_APDC7_ApeosPort_DocuCentre_VII_C7773_EN.html target=_blank>view online training guides</a></b>, <b><a href=https://www.youtube.com/fujixeroxsupport target=_blank>peruse online training videos</a></b>, or connect to a remote assistant using live video chat or phone:",
    "next": ["ra","+61429575654"]
    },
    {
    "id": 11,
    "q": "Please <b><a href=https://onlinesupport.fujixerox.com/setupSupport.do?cid=2&ctry_code=AU&lang_code=en target=_blank>visit the online support page</a></b> or connect to a remote assistant using live video chat or phone:",
    "next": ["ra","+61429575654"]
    },
    {
    "id": 12,
    "q": "Sorry to hear that your <b>{{printerName}}</b> has a paper jam. Please point the phone at the device and follow the video attached to the problem area.",
    "next": ["showARVideo",13]
    },
    {
    "id": 13,
    "q": "Did that fix the problem?",
    "next": [9,10],
    "nextLabels": ["Yes","No"]
    },
    {
    "id": 14,
    "q": "I see you are on a {{deviceType}}. Do you want to print from:",
    "next": ["15m16m17",17],
    "nextLabels": ["A mobile device","A desktop"]
    },
    {
    "id": 15,  
    "q": "You're on Android, so please download this app from the Google Play Store using the link below.",
    "next": ["https://play.google.com/store/apps/details?id=com.xerox.printservice",13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 16,
    "q": "Your're on iOS, so you can print natively from your iPhone using AirPrint. Please <b><a href=http://m1-onlinesupport.fujixerox.com/driver_downloads/OTS/AP7C7773/OTS_Solution16160_EN.html target=_blank>view this instruction guide</a></b> or watch the video below:
    <p class=\\"mt-4\\">
    <strong>How to Print to ANY Printer from iPhone, iPod, iPad via Windows</strong>
    <a href=\\"https://youtu.be/P_64MdjFoL0\\" target=\\"_blank\\">
    <img class=\\"img-thumbnail\\" src=\\"http://i3.ytimg.com/vi/P_64MdjFoL0/hqdefault.jpg\\" />
    </a>
    </p>",
    "next": ["https://www.youtube.com/watch?v=P_64MdjFoL0",13]
    },
    {
    "id": 17,
    "q": "Please visit <b><a href=https://onlinesupport.fujixerox.com/setupDriverForm.do?ctry_code=SG&lang_code=en&d_lang=en&pid=AP7C7773 target=_blank>this link</a></b> on a desktop or <b><a href='mailto:?body=Hello!%0D%0A%0D%0AThese%20links%20can%20help%20you%20configure%20drivers%20on%20your%20device:%20https://bit.ly/2xdI9jV%20and%20https://bit.ly/2LGyEgJ&subject=Your%20Digital%20Companion%20link'>send email with instructions.</a></b>",
    "next": [13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 22,
    "q": "OK, great! We need to know your printer model. Please press the button below then frame your device's model name in the camera window.",
    "next": ["scanText",23],
    "url": "printerName",
    "setVar":"printerName"
    },
    {
    "id": 23,
    "q": "Great! You've got a <b>{{printerName}}</b>.
        <a href=\\"/static/images/printers/{{printerName}}.jpg\\" target=\\"_blank\\">
        <img class=\\"img-thumbnail\\" src=\\"/static/images/printers/{{printerName}}.jpg\\" />
        </a>
        For your <b>{{printerName}}</b> do you need to... ",
    "next": [19,20],
    "nextLabels": ["Order more toner","Install new toner"]
    },
    {
    "id": 19,
    "q": "Here are the part numbers for toner for your device: <b>{{partList}}</b>. Please <b><a href=https://www.fujixerox.com.au/en/Contact/Order-Supplies target=_blank>visit the digital store to purchase toner</a></b>.
          <div style='padding:10px 0px 0px 0px'>
          Did you know that Fuji Xerox provides automated toner replenishment using smart remote service? 
          <b><a href=https://www.fujixerox.co.nz/en/Company/EP-BB target=_blank>Find out more about applying for eligibility.</a></b>
          </div>",
    "next": [13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 20,
    "q": "You are ready to install toner. Please point your mobile at your printer and we'll show you how.",
    "next": ["showARScene",21],
    "nextLabels": ["Continue"]
    },
    {
    "id": 21,
    "q": "Now that you've seen how, please try replacing your toner cartridge.
    <b><a href=https://bit.ly/2z5FCIZ target=_blank>Find out more here</a></b> or
    <b><a href=https://www.youtube.com/watch?v=uNdh-eS9R_Q target=_blank>watch a video</a></b>.
    <p class=\\"mt-4\\">
    <strong>How To Remove or Replace the Toner Cartridge -Apeosport/DocuCentre VII C6673 -EN</strong>
    <a href=\\"https://youtu.be/uNdh-eS9R_Q\\" target=\\"_blank\\">
    <img class=\\"img-thumbnail\\" src=\\"http://i3.ytimg.com/vi/uNdh-eS9R_Q/hqdefault.jpg\\" />
    </a>
    </p>
    ",
    "next": [13],
    "nextLabels": ["Continue"]
    }
 ]
} `;



