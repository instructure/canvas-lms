//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// also requires
// jquery.formSubmit
// jqueryui dialog
// jquery disableWhileLoading

import {useScope as useI18nScope} from '@canvas/i18n'
import helpDialogTemplate from './jst/helpDialog.handlebars'
import $ from 'jquery'
import {find} from 'lodash'
import htmlEscape, {raw} from '@instructure/html-escape'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('helpDialog')

const helpDialog = {
  defaultTitle: I18n.t('Help', 'Help'),

  showEmail: () => !ENV.current_user_id,

  animateDuration: 100,

  initDialog() {
    helpDialog.defaultTitle = ENV.help_link_name || helpDialog.defaultTitle
    helpDialog.$dialog = $('<div style="padding:0; overflow: visible;" />').dialog({
      resizable: false,
      width: 400,
      title: helpDialog.defaultTitle,
      close: () => helpDialog.switchTo('#help-dialog-options'),
      modal: true,
      zIndex: 1000,
    })

    helpDialog.$dialog
      .dialog('widget')
      .on(
        'click',
        'a[href="#teacher_feedback"],a[href="#create_ticket"],a[href="#help-dialog-options"]',
        event => {
          if (event) event.preventDefault()
          helpDialog.switchTo($(event.currentTarget).attr('href'))
        }
      )

    helpDialog.helpLinksDfd = $.getJSON('/help_links').done(links => {
      // only show the links that are available to the roles of this user
      links = $.grep(links, link =>
        find(
          link.available_to,
          role =>
            role === 'user' || (ENV.current_user_roles && ENV.current_user_roles.includes(role))
        )
      )
      const locals = {
        showEmail: helpDialog.showEmail(),
        helpLinks: links,
        url: window.location,
        contextAssetString: ENV.context_asset_string,
        userRoles: ENV.current_user_roles,
      }

      helpDialog.$dialog.html(helpDialogTemplate(locals))
      helpDialog.initTicketForm()

      // recenter the dialog once all the links have been loaded so it is back in the
      // middle of the page
      if (helpDialog.$dialog) helpDialog.$dialog.dialog('option', 'position', 'center')

      $(this).trigger('ready')
    })
    helpDialog.$dialog.disableWhileLoading(helpDialog.helpLinksDfd)
    helpDialog.dialogInited = true
  },

  initTicketForm() {
    const required = ['error[subject]', 'error[comments]', 'error[user_perceived_severity]']
    if (helpDialog.showEmail()) required.push('error[email]')

    const $form = helpDialog.$dialog.find('#create_ticket').formSubmit({
      disableWhileLoading: true,
      required,
      success: () => {
        helpDialog.$dialog.dialog('close')
        $form.find(':input').val('')
      },
    })
  },

  switchTo(panelId) {
    let newTitle
    const toggleablePanels = '#teacher_feedback, #create_ticket'
    const homePanel = '#help-dialog-options'
    helpDialog.$dialog.find(toggleablePanels).hide()
    const newPanel = helpDialog.$dialog.find(panelId)
    const newHeight = newPanel.show().outerHeight()
    helpDialog.$dialog.animate(
      {left: toggleablePanels.match(panelId) ? -400 : 0, height: newHeight},
      {
        step: () => {
          // reposition vertically to reflect current height
          if (
            !(
              helpDialog.dialogInited &&
              helpDialog.$dialog &&
              helpDialog.$dialog.hasClass('ui-dialog-content')
            )
          ) {
            helpDialog.initDialog()
          }
          helpDialog.$dialog && helpDialog.$dialog.dialog('option', 'position', 'center')
        },
        duration: helpDialog.animateDuration,
        complete() {
          let toFocus = newPanel.find(':input').not(':disabled')
          if (!toFocus.length) toFocus = newPanel.find(':focusable')
          toFocus.first().focus()
          if (panelId !== homePanel) $(homePanel).hide()
        },
      }
    )

    if ((newTitle = helpDialog.$dialog.find(`a[href='${panelId}'] .text`).text())) {
      newTitle = $(
        `<a class='ui-dialog-header-backlink' href='#help-dialog-options'>
          ${htmlEscape(I18n.t('Back', 'Back'))} \
        </a>
        <span>
          ${htmlEscape(newTitle)}
        </span>`
      )
    } else {
      newTitle = helpDialog.defaultTitle
    }
    helpDialog.$dialog.dialog('option', 'title', newTitle)
  },

  open() {
    if (
      !(
        helpDialog.dialogInited &&
        helpDialog.$dialog &&
        helpDialog.$dialog.hasClass('ui-dialog-content')
      )
    ) {
      helpDialog.initDialog()
    }
    helpDialog.$dialog.dialog('open')
    helpDialog.initTeacherFeedback()
  },

  initTeacherFeedback() {
    const currentUserIsStudent =
      ENV.current_user_roles && ENV.current_user_roles.includes('student')
    if (!helpDialog.teacherFeedbackInited && currentUserIsStudent) {
      helpDialog.teacherFeedbackInited = true
      const coursesDfd = $.getJSON('/api/v1/courses.json')
      let $form
      helpDialog.helpLinksDfd.done(() => {
        $form = helpDialog.$dialog
          .find('#teacher_feedback')
          .disableWhileLoading(coursesDfd)
          .formSubmit({
            disableWhileLoading: true,
            required: ['recipients[]', 'body'],
            success: () => helpDialog.$dialog.dialog('close'),
          })
      })

      $.when(coursesDfd, helpDialog.helpLinksDfd).done(([courses]) => {
        const optionsHtml = $.map(
          courses,
          c =>
            `<option
            value='course_${c.id}_admins'
            ${raw(ENV.context_id === c.id ? 'selected' : '')}
          >
            ${htmlEscape(c.name)}
          </option>`
        ).join('')
        $form.find('[name="recipients[]"]').html(optionsHtml)
      })
    }
  },

  initTriggers() {
    $('.help_dialog_trigger').click(event => {
      event.preventDefault()
      helpDialog.open()
    })
  },
}
export default helpDialog
