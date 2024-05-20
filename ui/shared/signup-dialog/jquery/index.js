/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import registrationErrors from '@canvas/normalize-registration-errors'
import teacherDialog from '../jst/teacherDialog.handlebars'
import studentDialog from '../jst/studentDialog.handlebars'
import parentDialog from '../jst/parentDialog.handlebars'
import newParentDialog from '../jst/newParentDialog.handlebars'
import samlDialog from '../jst/samlDialog.handlebars'
import addPrivacyLinkToDialog from './addPrivacyLinkToDialog'
import htmlEscape from '@instructure/html-escape'
import './validate'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/datetime/jquery'
import '@canvas/util/jquery/fixDialogButtons'
import extensions from '@canvas/bundles/extensions'

const I18n = useI18nScope('registration')

const $nodes = {}

const templates = {
  teacherDialog,
  studentDialog,
  parentDialog,
  newParentDialog,
  samlDialog,
}

// # we do this in coffee because of this hbs 1.3 bug:
// # https://github.com/wycats/handlebars.js/issues/748
// # https://github.com/fivetanley/i18nliner-handlebars/commit/55be26ff
const termsHtml = function (arg) {
  const terms_of_use_url = arg.terms_of_use_url
  const privacy_policy_url = arg.privacy_policy_url
  return I18n.t(
    'teacher_dialog.agree_to_terms_and_pp',
    'You agree to the *terms of use* and acknowledge the **privacy policy**.',
    {
      wrappers: [
        '<a href="' + htmlEscape(terms_of_use_url) + '" target="_blank">$1</a>',
        '<a href="' + htmlEscape(privacy_policy_url) + '" target="_blank">$1</a>',
      ],
    }
  )
}

const signupDialog = function (id, title, path) {
  let el
  if (path == null) {
    path = null
  }
  if (!templates[id]) {
    return
  }
  const $node = $nodes[id] != null ? $nodes[id] : ($nodes[id] = $('<div />'))
  path || (path = '/users')
  const html = templates[id]({
    account: ENV.ACCOUNT.registration_settings,
    terms_required: ENV.ACCOUNT.terms_required,
    recaptcha: ENV.ACCOUNT.recaptcha_key,
    terms_html: termsHtml(ENV.ACCOUNT),
    path,
    require_email: ENV.ACCOUNT.registration_settings.require_email,
  })
  $node.html(html)
  $node.find('.signup_link').click(
    preventDefault(function () {
      $node.dialog('close')
      return signupDialog($(this).data('template'), $(this).prop('title'))
    })
  )
  const $form = $node.find('form')
  $form.formSubmit({
    required: (function () {
      let i, len
      const ref = $form.find(':input[name]').not('[type=hidden]')
      const results = []
      for (i = 0, len = ref.length; i < len; i++) {
        el = ref[i]
        results.push(el.name)
      }
      return results
    })(),
    disableWhileLoading: 'spin_on_success',
    errorFormatter: registrationErrors,
    success: (function (_this) {
      return function (data) {
        // they should now be authenticated (either registered or pre_registered)
        if (data.destination) {
          return (window.location = data.destination)
        } else if (data.course) {
          return (window.location = '/courses/' + data.course.course.id + '?registration_success=1')
        } else {
          return (window.location = '/?registration_success=1')
        }
      }
    })(this),
    error: (function (_this) {
      return function (data) {
        let error_msg
        if (ENV.ACCOUNT.recaptcha_key) {
          // eslint-disable-next-line no-undef
          grecaptcha.reset($form.attr('data-captcha-id'))
          $node.parent().find('.button_type_submit').prop('disabled', true)
        }
        if (data.error) {
          error_msg = data.error.message
          $("input[name='" + htmlEscape(data.error.input_name) + "']")
            .next('.error_message')
            .text(htmlEscape(error_msg))
          return $.screenReaderFlashMessage(error_msg)
        }
      }
    })(this),
  })
  $node.dialog({
    resizable: false,
    title,
    // eslint-disable-next-line no-restricted-globals
    width: Math.min(screen.width, 550),
    // eslint-disable-next-line no-restricted-globals
    height: screen.height > 750 ? 'auto' : screen.height,
    open() {
      let $captchaId
      $(this).find('a').eq(0).blur()
      // on open, provide focus to first focusable item for ease of accessibility
      $(this).find('.ui-dialog-titlebar-close').focus()
      if (ENV.ACCOUNT.recaptcha_key) {
        $(this)
          .find('.g-recaptcha')[0]
          .addEventListener(
            'load',
            function (evt) {
              // An explicit tabindex is needed for it to be tabbable in the dialog
              return (evt.target.tabIndex = 0)
            },
            true
          )
        // eslint-disable-next-line no-undef
        $captchaId = grecaptcha.render($(this).find('.g-recaptcha')[0], {
          sitekey: ENV.ACCOUNT.recaptcha_key,
          callback() {
            return $node
              .parent()
              .find('button[type=submit], .button_type_submit')
              .prop('disabled', false)
          },
          'expired-callback': function () {
            return $node
              .parent()
              .find('button[type=submit], .button_type_submit')
              .prop('disabled', true)
          },
        })
        $form.attr('data-captcha-id', $captchaId)
        $node.find('button[type=submit]').prop('disabled', true)
      }
      // eslint-disable-next-line no-void
      return typeof signupDialog.afterRender === 'function' ? signupDialog.afterRender() : void 0
    },
    close() {
      if (typeof signupDialog.teardown === 'function') {
        signupDialog.teardown()
      }
      return $('.error_box').filter(':visible').remove()
    },
    modal: true,
    zIndex: 1000,
  })
  $node.fixDialogButtons()
  // re-disable after fixing
  if (ENV.ACCOUNT.recaptcha_key) {
    $node.parent().find('.button_type_submit').prop('disabled', true)
  }
  if (!ENV.ACCOUNT.terms_required) {
    return addPrivacyLinkToDialog($node)
  }
}

signupDialog.templates = templates

const loadExtension = extensions['ui/shared/signup-dialog/jquery/index.js']?.()

const loadSignupDialog = loadExtension
  ? loadExtension.then(extension => extension.default(signupDialog))
  : Promise.resolve(signupDialog)

export {loadSignupDialog}
