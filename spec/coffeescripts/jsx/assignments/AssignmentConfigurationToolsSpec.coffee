define [
  'react'
  'jsx/assignments/AssignmentConfigurationTools'
], (React, AssignmentConfigurationTools) ->

  wrapper = null
  toolDefinitions = null
  secureParams = null

  createElement = (data = {}) ->
    React.createElement(AssignmentConfigurationTools.configTools, data)

  renderComponenet = (data = {}) ->
    React.render(createElement(data), wrapper)


  module 'AssignmentConfigurationsTools',
    setup: ->
      secureParams = "asdf234.lhadf234.adfasd23324"
      wrapper = document.getElementById('fixtures')
      toolDefinitions = [
        {
          'definition_type': 'ContextExternalTool'
          'definition_id': 8
          'name': 'assignment_configuration Text'
          'description': 'This is a Sample Tool Provider.'
          'domain': 'lti-tool-provider-example.herokuapp.com'
          'placements': 'assignment_configuration':
            'message_type': 'basic-lti-launch-request'
            'url': 'https://lti-tool-provider-example.herokuapp.com/messages/blti'
            'title': 'assignment_configuration Text'
        }
        {
          'definition_type': 'ContextExternalTool'
          'definition_id': 9
          'name': 'My LTI'
          'description': 'The most impressive LTI app'
          'domain': 'my-lti.docker'
          'placements': 'assignment_configuration':
            'message_type': 'basic-lti-launch-request'
            'url': 'http://my-lti.docker/course-navigation'
            'title': 'My LTI'
        }
        {
          'definition_type': 'ContextExternalTool'
          'definition_id': 7
          'name': 'Redirect Tool'
          'description': 'Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.'
          'domain': null
          'placements': 'assignment_configuration':
            'message_type': 'basic-lti-launch-request'
            'url': 'https://www.edu-apps.org/redirect'
            'title': 'Redirect Tool'
        }
        {
          'definition_type': 'Lti::MessageHandler'
          'definition_id': 5
          'name': 'Lti2Example'
          'description': null
          'domain': 'localhost'
          'placements': 'assignment_configuration':
            'message_type': 'basic-lti-launch-request'
            'url': 'http://localhost:3000/messages/blti'
            'title': 'Lti2Example'
        }
      ]
      @stub($, 'ajax', -> {status: 200, data: toolDefinitions})

    teardown: ->
      wrapper.innerHTML = ''

  test 'it renders', ->
    component = renderComponenet({'courseId': 1, 'secureParams': secureParams})
    ok component.isMounted()

  test 'it uses the correct tool definitions URL', ->
    courseId = 1
    correctUrl = "/api/v1/courses/#{courseId}/lti_apps/launch_definitions"
    component = renderComponenet({'courseId': courseId})
    equal component.getDefinitionsUrl(), correctUrl

  test 'it renders a "none" option', ->
    component = renderComponenet({'courseId': 1, 'secureParams': secureParams})
    component.setState({tools: toolDefinitions})
    option = wrapper.querySelector('option')
    equal option.getAttribute('data-launch'), 'none'

  test 'it renders each tool', ->
    component = renderComponenet({'courseId': 1, 'secureParams': secureParams})
    component.setState({tools: toolDefinitions})
    equal wrapper.querySelectorAll('option').length, toolDefinitions.length + 1

  test 'it builds the correct Launch URL for LTI 1 tools', ->
    component = renderComponenet({'courseId': 1, 'secureParams': secureParams})
    tool = toolDefinitions[0]
    correctUrl = "/courses/1/external_tools/retrieve?borderless=true&url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti&secure_params=" +
      secureParams
    computedUrl = component.getLaunch(tool)
    equal computedUrl, correctUrl

  test 'it builds the correct Launch URL for LTI 2 tools', ->
    component = renderComponenet({'courseId': 1, 'secureParams': secureParams})
    tool = toolDefinitions[3]
    correctUrl = "/courses/1/lti/basic_lti_launch_request/5?display=borderless&secure_params=" +
      secureParams
    computedUrl = component.getLaunch(tool)
    equal computedUrl, correctUrl


