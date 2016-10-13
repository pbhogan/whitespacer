{CompositeDisposable} = require "atom"

module.exports =
class Whitespacer
	constructor: ->
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.workspace.observeTextEditors (editor) =>
			@handleEvents(editor)

		@subscriptions.add atom.commands.add "atom-workspace",
			"whitespacer:remove-trailing-whitespace": =>
				if editor = atom.workspace.getActiveTextEditor()
					@removeTrailingWhitespace(editor, editor.getGrammar().scopeName)
			"whitespacer:convert-tabs-to-spaces": =>
				if editor = atom.workspace.getActiveTextEditor()
					@convertTabsToSpaces(editor)
			"whitespacer:convert-spaces-to-tabs": =>
				if editor = atom.workspace.getActiveTextEditor()
					@convertSpacesToTabs(editor)
			"whitespacer:convert-two-spaces-to-tabs": =>
				if editor = atom.workspace.getActiveTextEditor()
					@convertTwoSpacesToTabs(editor)


	destroy: ->
		@subscriptions.dispose()


	handleEvents: (editor) ->
		buffer = editor.getBuffer()
		bufferSavedSubscription = buffer.onWillSave =>
			buffer.transact =>
				scopeDescriptor = editor.getRootScopeDescriptor()
				if atom.config.get("whitespacer.removeTrailingWhitespace", scope: scopeDescriptor)
					@removeTrailingWhitespace(editor, editor.getGrammar().scopeName)

				count = atom.config.get("whitespacer.ensureTrailingNewlines", scope: scopeDescriptor)
				if count > 0
					@ensureTrailingNewlines editor, count

		editorTextInsertedSubscription = editor.onDidInsertText (event) ->
			return unless event.text is "\n"
			return unless buffer.isRowBlank(event.range.start.row)

			scopeDescriptor = editor.getRootScopeDescriptor()
			if atom.config.get("whitespacer.removeTrailingWhitespace", scope: scopeDescriptor)
				unless atom.config.get("whitespacer.ignoreWhitespaceOnlyLines", scope: scopeDescriptor)
					editor.setIndentationForBufferRow(event.range.start.row, 0)

		editorDestroyedSubscription = editor.onDidDestroy =>
			bufferSavedSubscription.dispose()
			editorTextInsertedSubscription.dispose()
			editorDestroyedSubscription.dispose()

			@subscriptions.remove(bufferSavedSubscription)
			@subscriptions.remove(editorTextInsertedSubscription)
			@subscriptions.remove(editorDestroyedSubscription)

		@subscriptions.add(bufferSavedSubscription)
		@subscriptions.add(editorTextInsertedSubscription)
		@subscriptions.add(editorDestroyedSubscription)


	removeTrailingWhitespace: (editor, grammarScopeName) ->
		buffer = editor.getBuffer()
		scopeDescriptor = editor.getRootScopeDescriptor()
		ignoreCurrentLine = atom.config.get("whitespacer.ignoreWhitespaceOnCurrentLine", scope: scopeDescriptor)
		ignoreWhitespaceOnlyLines = atom.config.get("whitespacer.ignoreWhitespaceOnlyLines", scope: scopeDescriptor)

		buffer.backwardsScan /[ \t]+$/g, ({lineText, match, replace}) ->
			whitespaceRow = buffer.positionForCharacterIndex(match.index).row
			cursorRows = (cursor.getBufferRow() for cursor in editor.getCursors())

			return if ignoreCurrentLine and whitespaceRow in cursorRows

			[whitespace] = match
			return if ignoreWhitespaceOnlyLines and whitespace is lineText

			if grammarScopeName is "source.gfm" and atom.config.get("whitespacer.keepMarkdownLineBreakWhitespace")
				# GitHub Flavored Markdown permits two or more spaces at the end of a line
				replace("") unless whitespace.length >= 2 and whitespace isnt lineText
			else
				replace("")


	ensureTrailingNewlines: (editor, count) ->
		buffer = editor.getBuffer()
		lastRow = buffer.getLastRow()

		# Find last row with content.
		row = lastRow
		while row and buffer.lineForRow(row) is ""
			row -= 1

		# Where end needs to be after spaces.
		end = row + count

		# Remove empty lines or add them as required.
		if end < lastRow
			buffer.deleteRow(lastRow--) while end < lastRow
		else
			selectedBufferRanges = editor.getSelectedBufferRanges()
			buffer.append Array(end + 1 - lastRow).join("\n")
			editor.setSelectedBufferRanges selectedBufferRanges


	convertTabsToSpaces: (editor) ->
		buffer = editor.getBuffer()
		spacesText = new Array(editor.getTabLength() + 1).join(" ")

		buffer.transact ->
			buffer.scan /\t/g, ({replace}) -> replace(spacesText)

		editor.setSoftTabs(true)


	convertSpacesToTabs: (editor) ->
		buffer = editor.getBuffer()
		spacesText = new Array(editor.getTabLength() + 1).join(" ")

		buffer.transact ->
			buffer.scan new RegExp(spacesText, "g"), ({replace}) -> replace("\t")

		editor.setSoftTabs(false)


	convertTwoSpacesToTabs: (editor) ->
		buffer = editor.getBuffer()
		buffer.transact ->
			buffer.scan /^(  )+/g, ({lineText, match, replace}) ->
				[whitespace] = match
				tabCount = whitespace.length / 2
				replace Array(tabCount + 1).join("\t")
		editor.setSoftTabs(false)

