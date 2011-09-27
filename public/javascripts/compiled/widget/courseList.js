(function() {
  /*
  requires:
    - CustomList => widget/CustomList.js
  */  jQuery(function() {
    var menu;
    menu = jQuery('#menu_enrollments');
    if (menu.length === 0) {
      return;
    }
    return jQuery.getJSON('/all_menu_courses', function(enrollments) {
      return window.courseList = new CustomList('#menu_enrollments', enrollments, {
        appendTarget: '#menu_enrollments'
      });
    });
  });
}).call(this);
