const CHAT_TREE_JSON = `
 { "responses": [ 
    {
	"id": 1,
	"q": "Hi, welcome to the Digital Companion! Are you ready to get started?",
	"next": [2],
	"nextLabels": ["Ready"]
	},
	{
	"id": 2,
	"q": "OK, great. To begin we need to find out your printer model. To do this, we’ll need to scan the serial number. Please indicate that you are ready or that you need assistance.",
	"next": [3,4],
	"nextLabels": ["Ready","I need assistance"]
	},
	{
	"id": 3,
	"q": "OK! Press the button below then frame the barcode in the camera window.",
	"next": ["barcode",5]
	},
	{
	"id": 4,
	"q": "OK, let's connect you with a remote expert",
	"next": ["ra"]
	},
    {
	"id": 5,
	"q": "Great. Would you like 1) help fixing my printer 2) help ordering printer parts or 3) to speak with someone?",
	"next": [6,7,8],
	"nextLabels": ["1","2","3"]
	},
	{
	"id": 6,
	"q": "For this model let's connect you with an assistant via phone",
	"next": ["+16508424823"]
	},
	{
	"id": 7,
	"q": "For this model please send contact us via email for an order request",
	"next": ["fxpaltest@gmail.com"]
	},
	{
	"id": 8,
	"q": "For this model let's connect you with a remote expert",
	"next": ["ra"]
	}
 ]
} `;



