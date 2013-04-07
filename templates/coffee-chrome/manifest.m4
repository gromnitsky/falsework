{
	"manifest_version": 2,
	"name": "<%= @classy %>",
	"description": "TODO: add a description",
	"version": "syscmd(`json < package.json version | tr -d \\n')",

	"background": {
		"scripts": ["lib/background.js"]
	}
}
