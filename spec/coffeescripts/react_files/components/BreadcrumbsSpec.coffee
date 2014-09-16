define [
  'react'
  'jquery'
  'compiled/react_files/components/Breadcrumbs'
  'compiled/models/Folder'
  '../mockFilesENV'
  'compiled/react_files/routes'
], (React, $, Breadcrumbs, Folder, mockFilesENV, routes) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'FolderChild',
    setup: ->
      React.addons.TestUtils.renderIntoDocument(routes)

      sampleProps =
        rootTillCurrentFolder: [new Folder(), new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'})]
        contextId: '1'
        contextType: 'courses'

      @component = React.renderComponent(Breadcrumbs(sampleProps), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'generates the home, rootFolder, and other links', ->
    $breadcrumbs = $(this.component.getDOMNode())
    equal $breadcrumbs.find('.home a').attr('href'), '/', 'correct home url'
    equal $breadcrumbs.find('li:nth-child(3) a').attr('href'), '/courses/1/files', 'rootFolder link has correct url'
    equal $breadcrumbs.find('li:nth-child(4) a').attr('href'), '/courses/1/files/folder/test_folder_name', 'correct url for child'
    equal $breadcrumbs.find('li:nth-child(4) a').text(), 'test_folder_name', 'shows folder names'
