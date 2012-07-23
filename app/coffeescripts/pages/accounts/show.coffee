define ['jquery', 'jqueryui/autocomplete'], ($) ->
  page =
    init: ->
      $('.courses .course, .groups .group').on 'focus mouseover', (e) ->
        $(this).find('.info').addClass('info_hover')

      $('.courses .course, .groups .group').on 'blur mouseout', (e) ->
        $(this).find('.info').removeClass('info_hover')

      if $('#new_course').length > 0
        reEscape = new RegExp('(\\' + ['/', '.', '*', '+', '?', '|', '(', ')', '[', ']', '{', '}', '\\'].join('|\\') + ')', 'g')
        $newCourseForm = $('#new_course')
        $courseName = $('#course_name')

        $courseName.autocomplete
          minLength: 4
          delay: 150
          source: ENV.ACCOUNT_COURSES_PATH
          select: (event, ui) ->
            window.location = $newCourseForm[0].action + '/' + ui.item.id

