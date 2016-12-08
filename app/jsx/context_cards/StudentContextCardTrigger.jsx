define([
  "jquery",
  "react",
  "react-dom",
  "jsx/context_cards/StudentContextTray",
  "jsx/context_cards/StudentCardStore"
], ($, React, ReactDOM, StudentContextTray, StudentCardStore) => {
  $(document).on(
    "click",
    ".student_context_card_trigger",
    function(event) {
      let {student_id, course_id} = $(event.target).data();
      if (ENV.STUDENT_CONTEXT_CARDS_ENABLED && student_id && course_id) {
        event.preventDefault();
        const container = document.getElementById('StudentContextTray__Container')
        const store = new StudentCardStore(student_id, course_id)
        ReactDOM.render(
          <StudentContextTray
            courseId={course_id}
            isLoading={true}
            isOpen={true}
            store={store}
            studentId={student_id}
            onClose={() => {
              ReactDOM.unmountComponentAtNode(container)
            }}
          />, container)
      }
    }
  );
});
