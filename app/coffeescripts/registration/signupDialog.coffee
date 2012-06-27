define [
  'compiled/fn/preventDefault'
  'compiled/registration/registrationSuccessDialog'
  'compiled/models/User'
  'compiled/models/Pseudonym'
  'compiled/loadDir!jst/registration teacherDialog studentDialog studentHigherEdDialog parentDialog'
  'compiled/object/flatten'
  'jquery.instructure_forms'
  'jquery.instructure_date_and_time'
], (preventDefault, registrationSuccessDialog, User, Pseudonym, templates, flatten) ->

  $nodes = {}

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
        if data.user.user.workflow_state is 'registered'
          # they should now be authenticated
          window.location = "/"
        else
          $node.dialog('close')
          registrationSuccessDialog(data.channel.communication_channel)
      formErrors: false
      error: (errors) ->
        $form.formErrors flatten
          user: User::normalizeErrors(errors.user)
          pseudonym: Pseudonym::normalizeErrors(errors.pseudonym)
          observee: Pseudonym::normalizeErrors(errors.observee)
        , arrays: false
        return

    $node.dialog
      resizable: false
      title: title
      width: 550
      open: ->
        $(this).find('a').eq(0).blur()
        $(this).find(':input').eq(0).focus()
      close: -> $('.error_box').filter(':visible').remove()
