define [
  'react'
  'jquery'
  'compiled/react_files/components/ShowFolder'
], (React, $, ShowFolder) ->

  Simulate = React.addons.TestUtils.Simulate

  constructComponent = () ->
    props =
      params:
        splat: ''
      onResolvePath: -> # noop
    component = React.renderComponent(ShowFolder(props), $('<div>').appendTo('body')[0])
    component

  removeComponent = (comp) ->
    React.unmountComponentAtNode(comp.getDOMNode().parentNode)

  module 'ShowFolder'

  test 'empty splat gets a trailing slash', ->
    comp = constructComponent()
    equal comp.buildFolderPath(''), '/'
    removeComponent(comp)

  test 'clean splat gets slash plus name', ->
    comp = constructComponent()
    equal comp.buildFolderPath('clean_folder_name'), '/clean_folder_name'
    removeComponent(comp)

  test 'splats with a trailing slash get encoded', ->
    comp = constructComponent()
    equal comp.buildFolderPath('extra_space '), '/extra_space%20'
    removeComponent(comp)

  test 'splats with a slash with do not get encoded', ->
    comp = constructComponent()
    equal comp.buildFolderPath('this/has/slashes'), '/this/has/slashes'
    removeComponent(comp)
