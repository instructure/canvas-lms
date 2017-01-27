import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import StudentContextTray from 'jsx/context_cards/StudentContextTray'
import StudentCardStore from 'jsx/context_cards/StudentCardStore'

  const handleClickEvent = (event) => {
    const studentId = $(event.target).attr('data-student_id');
    const courseId = $(event.target).attr('data-course_id');
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
  }

  $(document).on('click', '.student_context_card_trigger', handleClickEvent);

export default handleClickEvent;

