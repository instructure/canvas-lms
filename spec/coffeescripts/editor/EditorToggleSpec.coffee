define [
  'jquery'
  'compiled/editor/EditorToggle'
], ($, EditorToggle) ->

  fixtures = $("#fixtures")
  containerDiv = null

  module "EditorToggle",
    setup: ->
      containerDiv = $("<div></div>")
      fixtures.append(containerDiv)
    teardown: ->
      containerDiv.remove()
      fixtures.empty()

  test "it passes tinyOptions into getRceOptions", ->
    tinyOpts = {width: '100'}
    initialOpts = {tinyOptions: tinyOpts}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    equal(opts.tinyOptions, tinyOpts)

  test "it defaults tinyOptions to an empty object if none are given", ->
    initialOpts = {someStuff: null}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    deepEqual(opts.tinyOptions, {})

  test "@options.rceOptions argument is not modified after initialization", ->
    rceOptions = {focus: false, otherStuff: ''}
    initialOpts = {someStuff: null, rceOptions}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    editorToggle.getRceOptions()

    equal editorToggle.options.rceOptions.focus, false
    equal editorToggle.options.rceOptions.otherStuff, ''

  test "@options.rceOptions can extend the default RichContentEditor opts", ->
    rceOptions = {focus: false, otherStuff: ''}
    initialOpts = {someStuff: null, rceOptions}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    ok opts.tinyOptions
    equal opts.focus, false
    equal opts.otherStuff, rceOptions.otherStuff

  test "createDone does not throw error when editButton doesn't exist", ->
    @stub($.fn, 'click').callsArg(0)
    EditorToggle::createDone.call
      options: {doneText: ''}
      display: ->
    ok $.fn.click.called
