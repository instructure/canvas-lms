define [
  'jquery'
  'vendor/jquery.cookie'
], ($) ->

  authenticity_token = ->
    $.cookie('_csrf_token')

  $(document).on "submit", "form", ->
    $(this).find("input[name='authenticity_token']").val(authenticity_token())

  # return a function to be used elsewhere
  authenticity_token