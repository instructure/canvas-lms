define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'instructure-ui/Avatar',
  'jsx/context_cards/StudentContextTray',
  'jsx/context_cards/StudentCardStore'
], (React, ReactDOM, TestUtils, Avatar, StudentContextTray, StudentCardStore) => {

  module('StudentContextTray', (hooks) => {
    let store, subject
    const courseId = '1'
    const studentId = '1'

    hooks.beforeEach(() => {
      store = new StudentCardStore(courseId, studentId)
      subject = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
        />
      )
    })
    hooks.afterEach(() => {
      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    test('change on store should setState on component', () => {
      sinon.spy(subject, 'setState')
      store.setState({
        user: {name: 'username'}
      })
      ok(subject.setState.calledOnce)
      subject.setState.restore()
    })

    test("changing store should call setState", () => {
      const student2 = { id: '2', shortName: "Bob" }
      const store2 = new StudentCardStore(courseId, student2.id)
      store2.state.user = student2
      sinon.spy(subject, 'setState')
      subject.componentWillReceiveProps({
        store: store2,
        course: courseId,
        studentId: student2.id
      })
      ok(subject.setState.calledOnce)
      subject.setState.restore()
    })
  })
})
