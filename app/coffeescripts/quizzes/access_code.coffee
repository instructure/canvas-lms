define [
  'jquery'
], ($) ->

  preventDuplicateSubmissions = ->
    $('.access_code_form').submit (e) ->
      e.preventDefault()
      $(this).find('button').prop('disabled', true)
      $(this).trigger('submit.rails')

  $(document).ready -> preventDuplicateSubmissions()
