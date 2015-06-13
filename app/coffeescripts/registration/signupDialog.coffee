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
  'str/htmlEscape'
  'compiled/jquery/validate'
  'jquery.instructure_forms'
  'jquery.instructure_date_and_time'
], ($, _, I18n, preventDefault, registrationErrors, teacherDialog, studentDialog, parentDialog, addPrivacyLinkToDialog, htmlEscape) ->

  $nodes = {}
  templates = {teacherDialog, studentDialog, parentDialog}

  # we do this in coffee because of this hbs 1.3 bug:
  # https://github.com/wycats/handlebars.js/issues/748
  # https://github.com/fivetanley/i18nliner-handlebars/commit/55be26ff
  termsHtml = ({terms_of_use_url, privacy_policy_url}) ->
    I18n.t(
      "teacher_dialog.agree_to_terms_and_pp"
      "You agree to the *terms of use* and acknowledge the **privacy policy**."
      wrappers: [
        "<a href=\"#{htmlEscape terms_of_use_url}\" target=\"_blank\">$1</a>"
        "<a href=\"#{htmlEscape privacy_policy_url}\" target=\"_blank\">$1</a>"
      ]
    )

  signupDialog = (id, title) ->
    return unless templates[id]
    $node = $nodes[id] ?= $('<div />')
    html = templates[id](
      account: ENV.ACCOUNT.registration_settings
      terms_required: ENV.ACCOUNT.terms_required
      terms_html: termsHtml(ENV.ACCOUNT)
    )
    $node.html html
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
