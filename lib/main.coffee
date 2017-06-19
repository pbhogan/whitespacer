Whitespacer = require "./whitespacer"

module.exports =
	activate: ->
		@whitespacer = new Whitespacer()

	deactivate: ->
		@whitespacer?.destroy()
		@whitespacer = null

