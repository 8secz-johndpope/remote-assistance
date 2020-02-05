const CHAT_TREE_JSON = `
 { "responses": [ 
    {
	"id": 1,
	"q": "Question text 1?",
	"next": [2,3],
	"nextLabels": ["1","2"]
	},
	{
	"id": 2,
	"q": "Question text 2?",
	"next": [3,4],
	"nextLabels": ["Ready","I need assistance"]
	},
	{
	"id": 3,
	"q": "Question text 3?",
	"next": ["barcode",4]
	},
	{
	"id": 4,
	"q": "Question text 4?",
	"next": ["ra","email@email.com","+15107612345"]
	}
 ]
}`;



