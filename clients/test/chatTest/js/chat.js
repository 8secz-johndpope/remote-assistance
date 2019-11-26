const chatTreeJSON = `
 { "responses": [ 
    {
	"id": 1,
	"q": "Question text 1?",
	"next": [2,3]
	},
	{
	"id": 2,
	"q": "Question text 2?",
	"next": [3,4]
	},
	{
	"id": 3,
	"q": "Question text 3?",
	"next": ["barcode",4]
	},
	{
	"id": 4,
	"q": "Question text 4?",
	"next": ["ra","email","+15107612345"]
	}
 ]
}`;



