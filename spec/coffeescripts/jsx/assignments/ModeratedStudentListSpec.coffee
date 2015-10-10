define [
  'react'
  'jsx/assignments/ModeratedStudentList'
  'jsx/assignments/stores/ModerationStore'
  'jsx/assignments/actions/ModerationActions'
], (React, ModeratedStudentList, Store, Actions) ->

  TestUtils = React.addons.TestUtils

  module 'ModeratedStudentList',
  test "renders mark 1", ->
    store = new Store()
    score = 10
    moderatedStudentList = TestUtils.renderIntoDocument(ModeratedStudentList(store: store))
    store.addSubmissions([{id: 1, user: {display_name: 'steve'}, provisional_grades: [{score:score}]}])
    firstMark = TestUtils.scryRenderedDOMComponentsWithClass(moderatedStudentList, 'AssignmentList__Mark')[0].getDOMNode().textContent
    equal firstMark, score, "renders the first mark"
    React.unmountComponentAtNode(moderatedStudentList.getDOMNode().parentNode)


