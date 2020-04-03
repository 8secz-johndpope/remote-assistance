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
    "next": [4,18,11],
    "nextLabels": ["Fix my printer","I need to replace my printer toner","Speak to someone"]
    },
    {
    "id": 4,
    "q": "OK, great! We need to know your printer model. Please press the button below then frame your device's model name in the camera window.",
    "next": ["scanText",5],
    "url": "printerName",
    "setVar":"printerName"
    },
    {
    "id": 5,
    "q": "Great! You've got a {{printerName}}. Do you want to...",
    "next": [6,12,14],
    "nextLabels": ["address a fault code","clear a paper jam","install a print driver"]
    },
    {
    "id": 6,
    "q": "Sorry to hear that your {{printerName}} has faulted. So we can help you best, please scan your fault code.",
    "next": ["scanText",7],
    "url": "errorCode",
    "setVar":"errorCode"
    },
    {
    "id": 7,
    "q": "Got it. Please check out this video:",
    "next": ["https://www.youtube.com/watch?v=Sagg08DrO5U",8]
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
    "q": "Sorry about that. Please connect to a remote assistant.",
    "next": ["ra"]
    },
    {
    "id": 11,
    "q": "Please connect to a remote assistant.",
    "next": ["ra"]
    },
    {
    "id": 12,
    "q": "Sorry to hear that your {{printerName}} has a paper jam. Please point the phone at the device and follow the video attached to the problem area.",
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
    "next": ["15m16",17],
    "nextLabels": ["A mobile device","A desktop"]
    },
    {
    "id": 15,
    "q": "You're on Android, so please download <a href='intent://example.com#Intent;scheme=app;package=my.package.name;end;'>this app</a> from the Google Play Store.",
    "next": [13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 16,
    "q": "Your're on iOS, so you can print natively from your iPhone using AirPrint. Here's an instruction how to do it:",
    "next": ["https://www.youtube.com/watch?v=Sagg08DrO5U",13],
    "next": [13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 17,
    "q": "Please visit <a href=https://bit.ly/3c6Qs0w>this link</a> on a desktop or email to {{userEmail}} to download.",
    "next": [13],
    "nextLabels": ["Continue"]
    },
    {
    "id": 18,
    "q": "Do you... ",
    "next": [19,20],
    "nextLabels": ["need to order more toner","need to install new toner"]
    },
    {
    "id": 19,
    "q": "Here are the part numbers for toner for your device: {{partList}}. Please <a href=#>visit the digital store to purchase toner</a>.
          <div style='padding:10px 0px 0px 0px'>
          Did you know that Fuji Xerox provides automated toner replenishment using smart remote service? 
          Would you like to know more about applying for eligibility? 
          <a href=#>link to form</a> <a href=#>link to brochure</a> <a href=#>link to video</a></div>",
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
    "q": "Now that you've seen how, please try replacing your toner cartridge. <a href=#>Find out more here.</a>",
    "next": [13],
    "nextLabels": ["Continue"]
    }
 ]
} `;



