define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/muteAssignmentOption',
  'compiled/gradebook2/SetDefaultGradeDialog'
  'jquery'
], (React, ReactDOM, SetDefaultGradeOption, SetDefaultGradeDialog, $) ->

  wrapper = document.getElementById('fixtures')

  defaultProps = ->
    assignment: { id: '1', muted: false }

  renderComponent = (props) ->
    props = props || defaultProps()
    componentFactory = React.createFactory(SetDefaultGradeOption)
    ReactDOM.render(componentFactory(props), wrapper)

  module 'MuteAssignmentOption',
    setup: ->
      $('.ui-dialog').remove()
      @component = renderComponent()
    teardown: ->
      $('.ui-dialog').remove()
      $("[id^=ui-id-]").remove()
      ReactDOM.unmountComponentAtNode wrapper

  test 'mounts properly', ->
    ok renderComponent().isMounted()

  test 'displays "Mute Assignment" when assignment is unmuted', ->
    component = renderComponent()
    text = component.getDOMNode().children[0].innerHTML
    deepEqual(text, 'Mute Assignment')

  test 'displays "Unmute Assignment" when assignment is muted', ->
    props = {assignment: {id: '1', muted: true}}
    component = renderComponent(props)
    text = component.getDOMNode().children[0].innerHTML
    deepEqual(text, 'Unmute Assignment')

   test 'displays dialog on click', ->
     component = renderComponent()
     equal($('.ui-dialog').size(), 0)
     component.openDialog()
     equal($('.ui-dialog').size(), 1)

   test 'mute dialog displays when assignment is unmuted', ->
     component = renderComponent()
     component.openDialog()
     title = $('.ui-dialog-title')[0].innerHTML
     equal(title, 'Mute Assignment')

   test 'unmute dialog displays when assignment is muted', ->
     props = {assignment: {id: '1', muted: true}}
     component = renderComponent(props)
     component.openDialog()
     title = $('.ui-dialog-title')[0].innerHTML
     equal(title, 'Unmute Assignment')

   test '$subscribe to assignment_muting_toggled event after dialog is opened', ->
     subscribeStub = @stub($, 'subscribe')
     component = renderComponent()
     component.openDialog()
     ok subscribeStub.calledWith('assignment_muting_toggled')
