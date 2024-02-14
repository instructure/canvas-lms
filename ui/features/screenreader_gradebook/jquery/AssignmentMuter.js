/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import mute_dialog_template from '../jst/mute_dialog.handlebars'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.disableWhileLoading'
import 'jqueryui/dialog'
import 'jquery-tinypubsub'

const I18n = useI18nScope('assignment_muter')

export default class AssignmentMuter {
  constructor($link, assignment, url, setter, options) {
    ;['confirmUnmute', 'afterUpdate', 'showDialog', 'updateLink'].forEach(
      m => (this[m] = this[m].bind(this))
    )
    this.$link = $link
    this.assignment = assignment
    this.url = url
    this.setter = setter
    this.options = options
  }

  show(onClose) {
    if (this.options && this.options.openDialogInstantly) {
      if (this.assignment.muted) {
        this.confirmUnmute()
      } else {
        this.showDialog(onClose)
      }
    } else {
      this.$link = $(this.$link)
      this.updateLink()
      if (!this.options || this.options.canUnmute) {
        this.$link.click(event => {
          event.preventDefault()
          if (this.assignment.muted) {
            this.confirmUnmute()
          } else {
            this.showDialog(onClose)
          }
        })
      }
    }
  }

  updateLink() {
    this.$link.text(this.assignment.muted ? I18n.t('Unmute Assignment') : I18n.t('Mute Assignment'))
  }

  showDialog(onClose) {
    this.$dialog = $(mute_dialog_template()).dialog({
      buttons: [
        {
          text: I18n.t('Cancel'),
          class: 'Button',
          'data-action': 'cancel',
          click: () => this.$dialog.dialog('close'),
        },
        {
          text: I18n.t('Mute Assignment'),
          class: 'Button Button--primary',
          'data-action': 'mute',
          'data-text-while-loading': I18n.t('Muting Assignment...'),
          click: () =>
            this.$dialog.disableWhileLoading(
              $.ajaxJSON(this.url, 'put', {status: true}, this.afterUpdate)
            ),
        },
      ],
      open: () =>
        setTimeout(() => this.$dialog.parent().find('.ui-dialog-titlebar-close').focus(), 100),
      close: () => this.$dialog.remove(),
      resizable: false,
      width: 400,
      modal: true,
      zIndex: 1000,
    })
    this.$dialog.on('dialogclose', onClose)
  }

  afterUpdate(serverResponse) {
    const assignment = serverResponse.assignment
    if (this.setter) {
      this.setter(this.assignment, 'anonymize_students', assignment.anonymize_students)
      this.setter(this.assignment, 'muted', assignment.muted)
    } else {
      this.assignment.anonymize_students = assignment.anonymize_students
      this.assignment.muted = assignment.muted
    }
    if (!(this.options && this.options.openDialogInstantly)) this.updateLink()

    this.$dialog.dialog('close')
    $.publish('assignment_muting_toggled', [
      {
        ...this.assignment,
        anonymize_students: assignment.anonymize_students,
        muted: assignment.muted,
      },
    ])
  }

  confirmUnmute() {
    this.$dialog = $('<div />')
      .text(
        I18n.t(
          "This assignment is currently muted. That means students can't see their grades and feedback. Would you like to unmute now?"
        )
      )
      .dialog({
        buttons: [
          {
            text: I18n.t('Cancel'),
            class: 'Button',
            'data-action': 'cancel',
            click: () => this.$dialog.dialog('close'),
          },
          {
            text: I18n.t('unmute_button', 'Unmute Assignment'),
            class: 'Button Button--primary',
            'data-action': 'unmute',
            'data-text-while-loading': I18n.t('unmuting_assignment', 'Unmuting Assignment...'),
            click: () =>
              this.$dialog.disableWhileLoading(
                $.ajaxJSON(this.url, 'put', {status: false}, this.afterUpdate)
              ),
          },
        ],
        open: () =>
          setTimeout(() => this.$dialog.parent().find('.ui-dialog-titlebar-close').focus(), 100),
        close: () => this.$dialog.dialog('close'),
        resizable: false,
        title: I18n.t('unmute_assignment', 'Unmute Assignment'),
        width: 400,
        modal: true,
        zIndex: 1000,
      })
  }
}
