define [
  'jquery'
  'underscore'
  'i18n!registration'
  'compiled/fn/preventDefault'
  'compiled/registration/registrationErrors'
  'jst/registration/teacherDialog'
  'jst/registration/studentDialog'
  'jst/registration/parentDialog'
  'compiled/util/addPrivacyLinkToDialog'
  'compiled/jquery/validate'
  'jquery.instructure_forms'
  'jquery.instructure_date_and_time'
], ($, _, I18n, preventDefault, registrationErrors, teacherDialog, studentDialog, parentDialog, addPrivacyLinkToDialog) ->

  $nodes = {}
  templates = {teacherDialog, studentDialog, parentDialog}

  signupDialog = (id, title) ->
    return unless templates[id]
    $node = $nodes[id] ?= $('<div />')
    $node.html templates[id](
      account: ENV.ACCOUNT.registration_settings
      terms_required: ENV.ACCOUNT.terms_required
      terms_url: ENV.ACCOUNT.terms_of_use_url
      privacy_url: ENV.ACCOUNT.privacy_policy_url
    )
    $node.find('.date-field').datetime_field()

    $node.find('.signup_link').click preventDefault ->
      $node.dialog('close')
      signupDialog($(this).data('template'), $(this).prop('title'))

    $form = $node.find('form')
    $form.formSubmit
      required: (el.name for el in $form.find(':input[name]').not('[type=hidden]'))
      disableWhileLoading: 'spin_on_success'
      errorFormatter: registrationErrors
      success: (data) =>
        # they should now be authenticated (either registered or pre_registered)
        if data.course
          window.location = "/courses/#{data.course.course.id}?registration_success=1"
        else
          window.location = "/?registration_success=1"

    $node.dialog
      resizable: false
      title: title
      width: 550
      open: ->
        $(this).find('a').eq(0).blur()
        $(this).find(':input').eq(0).focus()
        signupDialog.afterRender?()
      close: ->
        signupDialog.teardown?()
        $('.error_box').filter(':visible').remove()
    $node.fixDialogButtons()
    unless ENV.ACCOUNT.terms_required # term verbiage has a link to PP, so this would be redundant
      addPrivacyLinkToDialog($node)

  signupDialog.templates = templates
  signupDialog
