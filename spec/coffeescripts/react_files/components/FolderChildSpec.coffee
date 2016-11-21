define [
  '../mockFilesENV'
  'react'
  'react-dom'
  'jquery'
  'compiled/react_files/components/FolderChild'
  'compiled/models/Folder'
], (mockFilesENV, React, ReactDOM, $, FolderChild, Folder) ->

  # Simulate = React.addons.TestUtils.Simulate

  # TEST_FOLDERS_COLLECTION_URL = '/courses/<course_id>/folders/<folder_id>/folders'

  # module 'FolderChild',
  #   setup: ->
  #     @div =  $('<div>').appendTo('#fixtures')[0]

  #     # React.addons.TestUtils.renderIntoDocument(routes)
  #     @currentFolder = new Folder()
  #     @currentFolder.folders.url = TEST_FOLDERS_COLLECTION_URL
  #     thisFolder = @currentFolder.folders.add({})
  #   teardown: ->
  #     $("#fixtures").empty()

  #     @sampleProps = (canManageFiles = false) ->
  #       model: thisFolder
  #       params:
  #         contextId: 'course_id'
  #         contextType: 'courses'
  #       userCanManageFilesForContext: canManageFiles
  #       dndOptions:
  #         onItemDragStart: ->
  #         onItemDragEnterOrOver: ->
  #         onItemDragLeaveOrEnd: ->
  #         onItemDrop: ->

  #     @component = ReactDOM.render(FolderChild(@sampleProps(true)), @div)

  #   teardown: ->
  #     ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)


  # test 'allows creating a new folder', ->
  #   input = $(@div).find('.ef-edit-name-form .input-block-level')[0] #@component.refs.newName.getDOMNode()
  #   equal input, document.activeElement, 'input is focused automatically'

  #   input.value = 'testing 123'
  #   ajaxSpy = @spy($, 'ajax')
  #   Simulate.submit(input.form)
  #   ok ajaxSpy.calledWithMatch({
  #     url: TEST_FOLDERS_COLLECTION_URL
  #     type: 'POST'
  #     data: '{"name":"testing 123"}'
  #   }), 'sends POST to create folder'
