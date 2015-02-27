define [
  'react'
  'react-router'
  'jquery'
  'compiled/react_files/modules/filesEnv'
  'compiled/react_files/components/Breadcrumbs'
  'compiled/models/Folder'
  '../mockFilesENV'
  '../TestLocation'
], (React, Router, $, filesEnv, BreadcrumbsComponent, Folder, mockFilesENV, TestLocation) ->

  Simulate = React.addons.TestUtils.Simulate
  {Route} = Router

  module 'Breadcrumbs'

  test 'generates the home, rootFolder, and other links', ->

    sampleProps =
      rootTillCurrentFolder: [
        new Folder(),
        new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'})
      ]
      contextId: '1'
      contextType: 'courses'


    location = new TestLocation([ '/courses/1/files/folder/test_folder_name' ]);
    routes = [
      Route path: "#{filesEnv.baseUrl}/folder/*", name: "folder", handler: BreadcrumbsComponent
      Route path: "#{filesEnv.baseUrl}/?", name: "rootFolder", handler: BreadcrumbsComponent
    ]
    div = $('<div>').appendTo('body')[0]

    Router.run routes, location, (Handler) ->
      React.render Handler(sampleProps), div, ->
        $breadcrumbs = $('#breadcrumbs')
        equal $breadcrumbs.find('.home a')?.attr('href'), '/', 'correct home url'
        equal $breadcrumbs.find('li:nth-child(3) a')?.attr('href'), '/courses/1/files/', 'rootFolder link has correct url'
        equal $breadcrumbs.find('li:nth-child(4) a')?.attr('href'), '/courses/1/files/folder/test_folder_name', 'correct url for child'
        equal $breadcrumbs.find('li:nth-child(4) a').text(), 'test_folder_name', 'shows folder names'

      React.unmountComponentAtNode(div)
