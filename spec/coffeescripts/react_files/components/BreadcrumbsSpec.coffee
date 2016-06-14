define [
  '../mockFilesENV'
  'react'
  'react-router'
  'jquery'
  'compiled/react_files/modules/filesEnv'
  'jsx/files/Breadcrumbs'
  'compiled/models/Folder'
  '../TestLocation'
  'helpers/fakeENV'
], (mockFilesENV, React, Router, $, filesEnv, BreadcrumbsComponent, Folder, TestLocation, fakeENV) ->

  {Route} = Router

  module 'Breadcrumbs',
    setup: ->
      @div = $('<div>').appendTo('#fixtures')[0]
      fakeENV.setup context_asset_string: "course_1"
    teardown: ->
      React.unmountComponentAtNode(@div)
      $("#fixtures").empty()
      fakeENV.teardown()

  asyncTest 'generates the home, rootFolder, and other links', ->
    sampleProps =
      rootTillCurrentFolder: [
        new Folder(),
        new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'})
      ]
      contextId: '1'
      contextType: 'courses'


    location = new TestLocation([ '/courses/1/files/folder/test_folder_name' ])
    routes = [
      React.createElement(Route, path: "#{filesEnv.baseUrl}/folder/*", name: "folder", handler: BreadcrumbsComponent)
      React.createElement(Route, path: "#{filesEnv.baseUrl}/?", name: "rootFolder", handler: BreadcrumbsComponent)
    ]

    Router.run routes, location, (Handler) =>
      React.render React.createElement(Handler, sampleProps), @div, ->
        start()
        $breadcrumbs = $('#breadcrumbs')
        ok($breadcrumbs.length > 0)
        equal $breadcrumbs.find('.home a')?.attr('href'), '/', 'correct home url'
        equal $breadcrumbs.find('li:nth-child(3) a')?.attr('href'), '/courses/1/files/', 'rootFolder link has correct url'
        equal $breadcrumbs.find('li:nth-child(4) a')?.attr('href'), '/courses/1/files/folder/test_folder_name', 'correct url for child'
        equal $breadcrumbs.find('li:nth-child(4) a').text(), 'test_folder_name', 'shows folder names'
