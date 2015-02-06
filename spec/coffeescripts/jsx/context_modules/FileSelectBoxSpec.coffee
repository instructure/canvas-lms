define [
  'jquery'
  'old_unsupported_dont_use_react'
  'jsx/context_modules/FileSelectBox'
], ($, React, FileSelectBox) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  renderComponent = ->
    React.renderComponent(FileSelectBox({contextString: 'test_3'}), wrapper)

  module 'FileSelectBox',
    setup: ->
      @server = sinon.fakeServer.create()

      @folders = [{
          "full_name": "course files",
          "id": 112,
          "parent_folder_id": null,
        },{
          "full_name": "course files/A",
          "id": 113,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/C",
          "id": 114,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/B",
          "id": 115,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/NoFiles",
          "id": 116,
          "parent_folder_id": 112,
        }]

      @files = [{
          "id": 1,
          "folder_id": 112
          "display_name": "cf-1"
        },{
          "id": 2,
          "folder_id": 113
          "display_name": "A-1"
        },{
          "id": 3,
          "folder_id": 114
          "display_name": "C-1"
        },{
          "id": 4,
          "folder_id": 115
          "display_name": "B-1"
        }]


      @server.respondWith "GET", /\/tests\/3\/files/, [200, { "Content-Type": "application/json" }, JSON.stringify(@files)]
      @server.respondWith "GET", /\/tests\/3\/folders/, [200, { "Content-Type": "application/json" }, JSON.stringify(@folders)]

      @component = renderComponent()

    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'it renders', ->
    ok @component.isMounted()

  test 'it should alphabetize the folder list', ->
    @server.respond()
    # This also tests that folders without files are not shown.
    childrenLabels = $(@component.refs.selectBox.getDOMNode()).children('optgroup').toArray().map( (x) -> x.label)
    expected = ['course files', 'course files/A', 'course files/B', 'course files/C']
    deepEqual childrenLabels, expected

  test 'it should show the loading state while files are loading', ->
    # Has aria-busy attr set to true for a11y
    equal $(this.component.refs.selectBox.getDOMNode()).attr('aria-busy'), 'true'
    equal $(this.component.refs.selectBox.getDOMNode()).children()[1].text, 'Loading...'
    @server.respond()
    # Make sure those things disappear when the content actually loads
    equal $(this.component.refs.selectBox.getDOMNode()).attr('aria-busy'), 'false'
    loading = $(this.component.refs.selectBox.getDOMNode()).children().toArray().filter( (x) -> x.text == 'Loading...')
    equal loading.length, 0