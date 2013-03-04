define [
  'jquery'
  'jquery.disableWhileLoading'
], ($) ->

  newCourseForm = ->
    changeEvents = 'change keyup input'
    showCourseCodeIfNeeded = ->
      if $nameInput.val().trim().length > 20
        $nameInput.unbind changeEvents, showCourseCodeIfNeeded
        $('#course_code_wrapper').slideDown('fast')

    $nameInput = $('#new_course_form [name="course[name]"]')
    $nameInput.bind changeEvents, showCourseCodeIfNeeded
    $('#new_course_form').submit -> $(this).disableWhileLoading($.Deferred())
