###
requires:
  - CustomList => widget/CustomList.js
###

jQuery ->
  menu = jQuery '#menu_enrollments'

  return if menu.length is 0 # :(

  jQuery.getJSON '/all_menu_courses', (enrollments) ->
    window.courseList = new CustomList '#menu_enrollments', enrollments,
      appendTarget: '#menu_enrollments'
