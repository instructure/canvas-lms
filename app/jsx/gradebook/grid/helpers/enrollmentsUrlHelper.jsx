define([
], function () {
  function EnrollmentsUrlHelper({ showConcluded = false, showInactive = false }) {
    if(showConcluded && showInactive) {
      return 'enrollments_with_concluded_and_inactive_url';
    } else if(showConcluded) {
      return 'enrollments_with_concluded_url';
    } else if(showInactive) {
      return 'enrollments_with_inactive_url';
    } else {
      return 'enrollments_url'
    }
  };

  return EnrollmentsUrlHelper;
});
