define [
  'underscore'
  'i18n!registration'
  'compiled/fn/preventDefault'
  'compiled/registration/registrationErrors'
  'jst/registration/teacherDialog'
  'jst/registration/studentDialog'
  'jst/registration/studentHigherEdDialog'
  'jst/registration/parentDialog'
  'jquery.instructure_forms'
  'jquery.instructure_date_and_time'
], (_, I18n, preventDefault, registrationErrors, teacherDialog, studentDialog, studentHigherEdDialog, parentDialog) ->

  $nodes = {}
  templates = {teacherDialog, studentDialog, studentHigherEdDialog, parentDialog}

  signupDialog = (id, title) ->
    return unless templates[id]
    $node = $nodes[id] ?= $('<div />')
    $node.html templates[id](
      terms_url: "http://www.instructure.com/terms-of-use"
    )
    $node.find('.date-field').datetime_field()

    $node.find('.signup_link').click preventDefault ->
      $node.dialog('close')
      signupDialog($(this).data('template'), $(this).prop('title'))

    $form = $node.find('form')
    promise = null
    $form.formSubmit
      beforeSubmit: ->
        promise = $.Deferred()
        $form.disableWhileLoading(promise)
      success: (data) =>
        # they should now be authenticated (either registered or pre_registered)
        if data.course
          window.location = "/courses/#{data.course.course.id}?registration_success=1"
        else
          window.location = "/?registration_success=1"
      formErrors: false
      error: (errors) ->
        promise.reject()
        if _.any(errors.user.birthdate ? [], (e) -> e.type is 'too_young')
          $node.find('.registration-dialog').text I18n.t('too_young_error_join_code', 'You must be at least %{min_years} years of age to use Canvas without a course join code.', min_years: ENV.USER.MIN_AGE)
          $node.dialog buttons: [
            text: I18n.t('ok', "OK")
            click: -> $node.dialog('close')
            class: 'btn-primary'
          ]
          return
        $form.formErrors registrationErrors(errors)

    $node.dialog
      resizable: false
      title: title
      width: 550
      open: ->
        $(this).find('a').eq(0).blur()
        $(this).find(':input').eq(0).focus()
      close: -> $('.error_box').filter(':visible').remove()
    $node.fixDialogButtons()
