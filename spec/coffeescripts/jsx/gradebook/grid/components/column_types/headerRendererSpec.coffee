define [
  'react'
  'jsx/gradebook/grid/components/column_types/headerRenderer'
  'jquery'
  'jquery.instructure_date_and_time'
  'translations/_core_en'
], (React, HeaderRenderer, $) ->

  wrapper = document.getElementById('fixtures')

  displayedDueDate = (component) ->
    component.refs.dueDate.getDOMNode().textContent

  defaultProps = () ->
    label: 'Column Label'
    columnData:
      assignment:
        due_at: '2015-07-17T05:59:59Z'
      enrollments: []
      submissions: {}

  renderComponent = (data) ->
    element = React.createElement(HeaderRenderer, data)
    React.render(element, wrapper)

  buildComponent = (props) ->
    columnData = props
    renderComponent(columnData)

  module 'HeaderRenderer',
    setup: ->
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'displays nothing if there is no assignment', ->
    props = defaultProps()
    props.columnData = {}

    component = buildComponent(props)
    deepEqual displayedDueDate(component), ''

  test 'displays "No due date" if the assignment has no due date and no overrides', ->
    props = defaultProps()
    props.columnData.assignment.due_at = null

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'No due date'

  test 'displays "No due date" if the assignment has no due date and one override with no due date', ->
    props = defaultProps()
    props.columnData.assignment.due_at = null
    props.columnData.assignment.overrides = [
      { title: 'section 1', due_at: null }
    ]

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'No due date'

  test 'displays the override due date if the assignment has no due date and one' +
  ' override with a due date', ->
    @stub($, 'sameYear').returns(true)
    props = defaultProps()
    props.columnData.assignment.due_at = null
    props.columnData.assignment.overrides = [
      { title: 'section 1', due_at: '2015-07-18T05:59:59Z' }
    ]

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'Due Jul 18'

  test 'displays "Multiple due dates" if the assignment has more than one override', ->
    props = defaultProps()
    props.columnData.assignment.due_at = null
    props.columnData.assignment.overrides = [
      { title: 'section 1', due_at: '2015-07-17T05:59:59Z' },
      { title: 'section 2', due_at: '2015-07-18T05:59:59Z' }
    ]

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'Multiple due dates'

  #this logic matches the logic in Assignment.coffee#multipleDueDates, which is
  #used to display due dates on the assignment page. I'm matching that logic
  #for the sake of consistency.
  test 'displays "Multiple due dates" if the assignment has more than one override,' +
  'even if those overrides do not have due dates themselves', ->
    props = defaultProps()
    props.columnData.assignment.due_at = null
    props.columnData.assignment.overrides = [
      { title: 'section 1', due_at: null },
      { title: 'section 2', due_at: null }
    ]

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'Multiple due dates'

  test 'calculates the correct due date string for an assignment due in the current year', ->
    @stub($, 'sameYear').returns(true)
    props = defaultProps()

    component = buildComponent(props)
    deepEqual component.headerDate(props.columnData), 'Due Jul 17'

  test 'calculates the correct due date string for an assignment due in a different year', ->
    @stub($, 'sameYear').returns(false)
    props = defaultProps()

    component = buildComponent(props)
    deepEqual component.headerDate(props.columnData), 'Due Jul 17, 2015'

  test 'displays due date without the year if the assignment has a due date (current year)', ->
    @stub($, 'sameYear').returns(true)
    props = defaultProps()

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'Due Jul 17'

  test 'displays due date with the year if the assignment has a due date (different year)', ->
    @stub($, 'sameYear').returns(false)
    props = defaultProps()

    component = buildComponent(props)
    deepEqual displayedDueDate(component), 'Due Jul 17, 2015'
