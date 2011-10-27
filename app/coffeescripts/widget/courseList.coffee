###
requires:
  - js!vendor/jquery-1.6.4.js
###
define 'compiled/widget/courseList', ['compiled/widget/CustomList'], (CustomList) ->

  init: ->
    jQuery ->
      menu = jQuery '#menu_enrollments'

      return if menu.length is 0 # :(

      jQuery.getJSON '/all_menu_courses', (enrollments) ->
        window.courseList = new CustomList '#menu_enrollments', enrollments,
          appendTarget: '#menu_enrollments'

