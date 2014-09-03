define [
  'react'
  'jquery'
  'compiled/react_files/components/Breadcrumbs'
  'compiled/models/Folder'
  'react-router'
], (React, $, Breadcrumbs, Folder, ReactRouter) ->
  Simulate = React.addons.TestUtils.Simulate


  # Need to pass in setup objects but doing the same test
  breadcrumbTest = (routerObject, test) =>
    sinon.stub(ReactRouter, 'Link').returns("/some_url")
    @breadcrumbs = React.renderComponent(Breadcrumbs(rootTillCurrentFolder: routerObject), $('<div>').appendTo('body')[0])

    test()

    ReactRouter.Link.restore()
    React.unmountComponentAtNode(@breadcrumbs.getDOMNode().parentNode)

  module 'Breadcrumbs#render',
  test 'generates the rootFolder link', ->
    routerObject =
      [
        new Folder(name: 'folder')
      ]

    breadcrumbTest routerObject, ->
      ok ReactRouter.Link.calledWith(to: 'rootFolder', contextType: undefined, contextId: undefined, splat: "", activeClassName: 'active'), 'called with correct parameters for rootFolder' 
  test 'generates a folder link', ->
    folder = new Folder(name: 'folder')
    folder.urlPath = -> "somePath"
    routerObject =
      [
        folder
      ]

    breadcrumbTest routerObject, ->
      ok ReactRouter.Link.calledWith(to: 'folder', contextType: undefined, contextId: undefined, splat: "somePath", activeClassName: 'active'), 'called with correct parameters for a folder link' 
  
