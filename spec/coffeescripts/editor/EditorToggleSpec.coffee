define [
  'jquery',
  'compiled/editor/EditorToggle'
], ($, EditorToggle)->

  fixtures = $("#fixtures")
  containerDiv = null

  module "EditorToggle",
    setup: ->
      containerDiv = $("<div></div>")
      fixtures.append(containerDiv)
    teardown: ->
      containerDiv.remove()
      fixtures.empty()

  test "it passes tinyOptions into rceOptions", ->
    tinyOpts = {width: '100'}
    initialOpts = {tinyOptions: tinyOpts}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    rceOptions = editorToggle.rceOptions()

    equal(rceOptions.tinyOptions, tinyOpts)

  test "it defaults tinyOptions to an empty object if none are given", ->
    opts = {someStuff: null}
    editorToggle = new EditorToggle(containerDiv, opts)
    rceOptions = editorToggle.rceOptions()

    deepEqual(rceOptions.tinyOptions, {})
