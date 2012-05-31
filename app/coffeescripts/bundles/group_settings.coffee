require [
  'jquery'
  'i18n!group_settings'
  'compiled/fn/preventDefault'
  'jquery.instructure_forms'
], ($, I18n, preventDefault) ->

  $form = $('.group_avatar_form')
  $changeLink = $('.change_group_pic')

  toggleForm = ->
    $form.toggle()
    $changeLink.toggle()

  $form.formSubmit(
    success: (data) ->
      $('.avatar').attr('src', data.avatar_url)
      toggleForm()
    fileUpload: true
    preparedFileUpload: true
    singleFile: true
    handle_files: (a, data) ->
      data.avatar_id = a.attachment.id
      data
    context_code: 'group_' + ENV.GROUP_ID
    folder_id: ENV.FOLDER_ID
    formDataTarget: 'url'
    method: 'PUT'
    disableWhileLoading: true
  )

  $changeLink.click preventDefault ->
    toggleForm()

  $('.cancel_avatar').click preventDefault ->
    toggleForm()
