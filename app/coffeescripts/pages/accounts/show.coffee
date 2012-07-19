define ['jquery', 'jqueryui/autocomplete'], ($) ->
  page =
    init: ->
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

