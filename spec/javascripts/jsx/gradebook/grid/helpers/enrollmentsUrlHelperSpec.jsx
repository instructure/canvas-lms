define([
  'jsx/gradebook/grid/helpers/enrollmentsUrlHelper'
], (EnrollmentsUrlHelper) => {
  module("EnrollmentsUrlHelper");

  test("when showConcluded and showInactive are false", () => {
    var url = EnrollmentsUrlHelper({ showConcluded: false, showInactive: false });
    equal(url, 'enrollments_url');
  });

  test("when showConcluded is true", () => {
    var url = EnrollmentsUrlHelper({ showConcluded: true, showInactive: false });
    equal(url, 'enrollments_with_concluded_url');
  });

  test("when showInactive is true", () => {
    var url = EnrollmentsUrlHelper({ showConcluded: false, showInactive: true});
    equal(url, 'enrollments_with_inactive_url');
  });

  test("when showConcluded and showInactive is true", () => {
    var url = EnrollmentsUrlHelper({ showConcluded: true, showInactive: true});
    equal(url, 'enrollments_with_concluded_and_inactive_url');
  });
});
