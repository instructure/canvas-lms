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
      sinon.stub(store, 'loadDataForStudent')
      subject = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
        />
      )
    })
    hooks.afterEach(() => {
      store.loadDataForStudent.restore()

      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    test('change on store should setState on component', () => {
      subject = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
        />
      )
      sinon.spy(subject, 'setState')
      store.setState({
        user: {name: 'username'}
      })
      ok(subject.setState.calledOnce)
      subject.setState.restore()
    })
  })
})
