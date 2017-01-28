define([
  'jquery',
  'react',
  'react-dom',
  'jsx/context_cards/StudentContextTray',
  'jsx/context_cards/StudentCardStore'
], ($, React, ReactDOM, StudentContextTray, StudentCardStore) => {
  $(document).on('click', '.student_context_card_trigger', (event) => {
    const {student_id: studentId, course_id: courseId} = $(event.target).data();
    if (ENV.STUDENT_CONTEXT_CARDS_ENABLED && studentId && courseId) {
      event.preventDefault();
      const container = document.getElementById('StudentContextTray__Container')
      const store = new StudentCardStore(studentId, courseId)
      store.load()
      ReactDOM.render(
        <StudentContextTray
          isLoading
          isOpen
          courseId={courseId}
          store={store}
          studentId={studentId}
          onClose={() => {
            ReactDOM.unmountComponentAtNode(container)
          }}
        />, container
      )
    }
  });
});
