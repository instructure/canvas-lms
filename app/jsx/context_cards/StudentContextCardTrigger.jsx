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

      const returnFocusToHandler = () => {
        const focusableItems = [$(event.target)];
        if ($('.search-query')) {
          focusableItems.push($('.search-query'))
        }
        if ($('[name="search_term"]')) {
          focusableItems.push($('[name="search_term"]'))
        }

        return focusableItems;
      }

      ReactDOM.render(
        <StudentContextTray
          key={`student_context_card_${courseId}_${studentId}`}
          courseId={courseId}
          store={store}
          studentId={studentId}
          returnFocusTo={returnFocusToHandler}
          onClose={() => {
            ReactDOM.unmountComponentAtNode(container)
          }}
        />, container
      )
    }
  });
});
