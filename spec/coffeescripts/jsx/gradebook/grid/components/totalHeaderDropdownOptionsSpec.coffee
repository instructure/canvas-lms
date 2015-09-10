define [
  'jsx/gradebook/grid/components/totalHeaderDropdownOptions'
], (DropdownOptions) ->

  wrapper = document.getElementById('fixtures')

  renderComponent = (data) ->
    componentFactory = React.createFactory(DropdownOptions)
    React.render(componentFactory(data), wrapper)

  module 'TotalHeaderDropdownOptions',
    setup: ->
      @component = renderComponent({ idAttribute: 'dropdownOptions'})
    teardown: ->
      React.unmountComponentAtNode wrapper

  #TODO: make switch to points a toggle between points/percent and
  #make Move to front a toggle between front/end
  test 'includes options for Switch to Points and Move to Front', ->
    ok @component.refs.switchToPoints
    ok @component.refs.moveToFront

  test 'includes a toggle for current grade/final grade', ->
    ok @component.refs.currentOrFinalToggle
