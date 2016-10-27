define [
  'react'
  'react-dom'
  'underscore'
  'jsx/gradebook/grid/components/dropdown_components/messageStudentsWhoOption'
  'jsx/gradebook/grid/helpers/messageStudentsWhoHelper'
  'timezone'
], (React, ReactDOM, _, MessageStudentsWhoOption, MessageStudentsWhoHelper, tz) ->

  wrapper = document.getElementById('fixtures')

  renderComponent = (options) ->
    opts = options || {}
    assignment = { id: '1',  assignment_visibility: ['3'] }
    defaultProps =
      title: 'Message Students Who...'
      assignment: assignment
      enrollments: [
        {
          id: '14'
          course_id: '1',
          user_id: '3',
          type: 'StudentEnrollment',
          user: { id: '3', name: 'Dora' }
        }
      ]
      submissions: {}
    props = _.defaults(opts, defaultProps)
    componentFactory = React.createFactory(MessageStudentsWhoOption)
    ReactDOM.render(componentFactory(props), wrapper)

  module 'MessageStudentsWhoOption',
    setup: ->
      @component = renderComponent()
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'mounts on build', ->
    ok renderComponent().isMounted()

  test 'openDialog calls MessageStudentsWhoHelper#settings with the correct arguments', ->
    @stub window, 'messageStudents'
    settingsStub = @stub MessageStudentsWhoHelper, 'settings'
    @component.openDialog()
    ok settingsStub.calledOnce
    expectedStudents = [{ id: '3', name: 'Dora', score: null, submitted_at: null }]

    deepEqual settingsStub.args[0][0], @component.props.assignment
    deepEqual settingsStub.args[0][1], expectedStudents

  module 'MessageStudentsWhoOption#combineStudentsWithScores',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'returns students with their scores for an assignment', ->
    submissions = {
      2: [{
        user_id: 3,
        section_id: 1,
        submissions: [{ id: 16, assignment_id: 1, user_id: 3, score: 8, submitted_at: tz.parse('Nov 22, 2015') }]
      }],
    }
    component = renderComponent({ submissions: submissions })
    students = { 3: { id: '3', name: 'Dora' } }
    studentWithScore = component.combineStudentsWithScores(students)[0]
    expectedStudentWithScore = { id: '3', name: 'Dora', score: 8, submitted_at: tz.parse('Nov 22, 2015') }

    propEqual studentWithScore, expectedStudentWithScore

  test 'returns null for score and submitted_at if the student does not have a submission', ->
    component = renderComponent()
    students = { 3: { id: '3', name: 'Dora' } }
    studentWithScore = component.combineStudentsWithScores(students)[0]
    expectedStudentWithScore = { id: '3', name: 'Dora', score: null, submitted_at: null }

    propEqual studentWithScore, expectedStudentWithScore
