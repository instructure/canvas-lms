define [
  'react'
  'react-dom'
  'react-modal'
  'jsx/external_apps/components/AddApp'
], (React, ReactDOM, Modal, AddApp) ->

  TestUtils = React.addons.TestUtils
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  handleToolInstalled = ->
    ok true, 'handleToolInstalled called successfully'

  createElement = (data) ->
    React.createElement(AddApp, {
      handleToolInstalled: data.handleToolInstalled
      app: data.app
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component = renderComponent(data)
    addToolButtonNode = component.refs.addTool?.getDOMNode()
    modalNode = component.refs.modal?.getDOMNode()
    [ component, addToolButtonNode, modalNode ]

  module 'ExternalApps.AddApp',
    setup: ->
      @app = {
        "config_options": []
        "config_xml_url": "https://www.eduappcenter.com/configurations/g7lthtepu68qhchz.xml"
        "description": "Acclaim is the easiest way to organize and annotate videos for class."
        "id": 289
        "is_installed": false
        "name": "Acclaim"
        "requires_secret": true
        "short_name": "acclaim_app"
        "status": "active"
      }
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      handleToolInstalled: handleToolInstalled
      app: @app
    [ component, addToolButtonNode, modalNode ] = getDOMNodes(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, AddApp)

  test 'configOptions', ->
    data =
      handleToolInstalled: handleToolInstalled
      app: @app
    [ component, addToolButtonNode, modalNode ] = getDOMNodes(data)
    options = component.configOptions()
    equal options[0].props.name, 'name'
    equal options[1].props.name, 'consumer_key'
    equal options[2].props.name, 'shared_secret'

  test 'configSettings', ->
    @app['config_options'] = [{"name": "param1","param_type": "text", "default_value": "val1"}]

    data =
      handleToolInstalled: handleToolInstalled
      app: @app
    [ component, addToolButtonNode, modalNode ] = getDOMNodes(data)

    correctSettings =
      param1: 'val1'
      name: 'Acclaim'

    deepEqual component.configSettings(), correctSettings

  test 'mounting sets fields onto state', ->
    data =
      handleToolInstalled: handleToolInstalled
      app: @app
    component = renderComponent(data)
    deepEqual component.state,
      errorMessage: null
      fields: {
        consumer_key: { description: "Consumer Key", required: true, type: "text", value: "" }
        name: { description: "Name", required: true, type: "text", value: "Acclaim" }
        shared_secret: { description: "Shared Secret", required: true, type: "text", value: "" }
      }
      invalidFields: ["consumer_key", "shared_secret"]
      isValid: false
      modalIsOpen: false
