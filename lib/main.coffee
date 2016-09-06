Whitespacer = require "./whitespacer"

module.exports =
	activate: ->
		console.log "activate whitespacer"
		@whitespacer = new Whitespacer()

	deactivate: ->
		@whitespacer?.destroy()
		@whitespacer = null
