###
requires:
  - js!vendor/jquery-1.6.4.js
###
define 'compiled/widget/courseList', ['compiled/widget/CustomList'], (CustomList) ->

  init: ->
    jQuery ->
      $menu = jQuery '#menu_enrollments'
      $menuDrop = $menu.closest('.menu-item-drop')

      return if $menu.length is 0 # :(

      jQuery.subscribe 'menu/hovered', loadCourses = (elem) ->
        return unless $(elem).find($menu).find('.customListOpen').length
        jQuery.unsubscribe 'menu/hovered', loadCourses

        autoOpen = false
        $menu.delegate '.customListOpen', 'click', ->
          autoOpen = true

        jQuery.getJSON '/all_menu_courses', (enrollments) ->
          window.courseList = new CustomList '#menu_enrollments', enrollments,
            appendTarget: '#menu_enrollments'
            autoOpen: autoOpen
            onToggle: (state) -> $menuDrop.toggleClass 'menuCustomListEditing', state
