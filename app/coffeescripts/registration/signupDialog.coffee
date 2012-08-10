define [
  'underscore'
  'i18n!registration'
  'compiled/fn/preventDefault'
  'compiled/models/User'
  'compiled/models/Pseudonym'
  'jst/registration/teacherDialog'
  'jst/registration/studentDialog'
  'jst/registration/studentHigherEdDialog'
  'jst/registration/parentDialog'
  'compiled/object/flatten'
  'jquery.instructure_forms'
  'jquery.instructure_date_and_time'
], (_, I18n, preventDefault, User, Pseudonym, teacherDialog, studentDialog, studentHigherEdDialog, parentDialog, flatten) ->

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
    $form.formSubmit
      disableWhileLoading: true
      success: (data) =>
        # they should now be authenticated (either registered or pre_registered)
        window.location = "/?login_success=1&registration_success=1"
      formErrors: false
      error: (errors) ->
        if _.any(errors.user.birthdate ? [], (e) -> e.type is 'too_young')
          $node.find('.registration-dialog').html I18n.t('too_young_error', 'You must be at least %{min_years} years of age to use Canvas without a course join code.', min_years: ENV.USER.MIN_AGE)
          $node.dialog buttons: [
            text: I18n.t('ok', "OK")
            click: -> $node.dialog('close')
            class: 'btn-primary'
          ]
          return
        $form.formErrors flatten
          user: User::normalizeErrors(errors.user)
          pseudonym: Pseudonym::normalizeErrors(errors.pseudonym)
          observee: Pseudonym::normalizeErrors(errors.observee)
        , arrays: false

    $node.dialog
      resizable: false
      title: title
      width: 550
      open: ->
        $(this).find('a').eq(0).blur()
        $(this).find(':input').eq(0).focus()
      close: -> $('.error_box').filter(':visible').remove()
    $node.fixDialogButtons()
