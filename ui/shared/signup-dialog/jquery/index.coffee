#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import I18n from 'i18n!registration'
import preventDefault from 'prevent-default'
import registrationErrors from '@canvas/normalize-registration-errors'
import teacherDialog from '../jst/teacherDialog.handlebars'
import studentDialog from '../jst/studentDialog.handlebars'
import parentDialog from '../jst/parentDialog.handlebars'
import newParentDialog from '../jst/newParentDialog.handlebars'
import samlDialog from '../jst/samlDialog.handlebars'
import addPrivacyLinkToDialog from './addPrivacyLinkToDialog'
import htmlEscape from 'html-escape'
import './validate'
import '@canvas/forms/jquery/jquery.instructure_forms'
import '@canvas/datetime'

$nodes = {}
templates = {teacherDialog, studentDialog, parentDialog, newParentDialog, samlDialog}

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

signupDialog = (id, title, path=null) ->
  return unless templates[id]
  $node = $nodes[id] ?= $('<div />')
  path ||= "/users"
  html = templates[id](
    account: ENV.ACCOUNT.registration_settings
    terms_required: ENV.ACCOUNT.terms_required
    recaptcha: ENV.ACCOUNT.recaptcha_key
    terms_html: termsHtml(ENV.ACCOUNT)
    path: path
    require_email: ENV.ACCOUNT.registration_settings.require_email
  )
  $node.html html
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
      if data.destination
        window.location = data.destination
      else if data.course
        window.location = "/courses/#{data.course.course.id}?registration_success=1"
      else
        window.location = "/?registration_success=1"
    error: (data) =>
      if ENV.ACCOUNT.recaptcha_key
        grecaptcha.reset($form.attr('data-captcha-id'))
        $node.parent().find('.button_type_submit').prop('disabled', true )
      if data.error
        error_msg = data.error.message
        $("input[name='#{htmlEscape data.error.input_name}']").
        next('.error_message').
        text(htmlEscape error_msg)
        $.screenReaderFlashMessage(error_msg)

  $node.dialog
    resizable: false
    title: title
    width: Math.min(screen.width, 550)
    height: if screen.height > 750 then 'auto' else screen.height
    open: ->
      $(this).find('a').eq(0).blur()
      # on open, provide focus to first focusable item for ease of accessibility
      $(this).find('button.ui-dialog-titlebar-close').focus()
      if ENV.ACCOUNT.recaptcha_key
        $(this).find('.g-recaptcha')[0].addEventListener('load', (evt) ->
          # An explicit tabindex is needed for it to be tabbable in the dialog
          evt.target.tabIndex = 0;
        , true);
        $captchaId = grecaptcha.render($(this).find('.g-recaptcha')[0], {
          'sitekey': ENV.ACCOUNT.recaptcha_key,
          'callback': -> $node.parent().find('button[type=submit], .button_type_submit').prop('disabled', false),
          'expired-callback': -> $node.parent().find('button[type=submit], .button_type_submit').prop('disabled', true)
        })
        $form.attr('data-captcha-id', $captchaId)
        $node.find('button[type=submit]').prop('disabled', true )
      signupDialog.afterRender?()
    close: ->
      signupDialog.teardown?()
      $('.error_box').filter(':visible').remove()
  $node.fixDialogButtons()
  # re-disable after fixing
  if ENV.ACCOUNT.recaptcha_key
    $node.parent().find('.button_type_submit').prop('disabled', true )
  unless ENV.ACCOUNT.terms_required # term verbiage has a link to PP, so this would be redundant
    addPrivacyLinkToDialog($node)

signupDialog.templates = templates
export default signupDialog
