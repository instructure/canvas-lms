define(["jquery"], ($) => {
  $(document).on(
    "click",
    ".student_context_card_trigger",
    function(event) {
      let {student_id, course_id} = $(event.target).data();
      if (ENV.STUDENT_CONTEXT_CARDS_ENABLED && student_id && course_id) {
        event.preventDefault();
        alert(`Student context tray! student=${student_id} course=${course_id}`);
      }
    }
  );
});
