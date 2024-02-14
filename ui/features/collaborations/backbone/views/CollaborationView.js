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

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import CollaboratorPickerView from './CollaboratorPickerView'
import editForm from '../../jst/edit.handlebars'
import editIframe from '../../jst/EditIframe.handlebars'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'

const I18n = useI18nScope('collaborations')

extend(CollaborationView, View)

function CollaborationView() {
  this.delete = this.delete.bind(this)
  this.handleAlertBlur = this.handleAlertBlur.bind(this)
  return CollaborationView.__super__.constructor.apply(this, arguments)
}

CollaborationView.prototype.events = {
  'click .edit_collaboration_link': 'onEdit',
  'keyclick .edit_collaboration_link': 'onEdit',
  'click .delete_collaboration_link': 'onDelete',
  'keyclick .delete_collaboration_link': 'onDelete',
  'click .cancel_button': 'onCloseForm',
  'focus .before_external_content_info_alert': 'handleAlertFocus',
  'focus .after_external_content_info_alert': 'handleAlertFocus',
  'blur .before_external_content_info_alert': 'handleAlertBlur',
  'blur .after_external_content_info_alert': 'handleAlertBlur',
}

CollaborationView.prototype.initialize = function () {
  CollaborationView.__super__.initialize.apply(this, arguments)
  return (this.id = this.$el.data('id'))
}

CollaborationView.prototype.handleAlertFocus = function (e) {
  $(e.target).removeClass('screenreader-only')
  return this.$el.find('iframe').addClass('info_alert_outline')
}

CollaborationView.prototype.handleAlertBlur = function (e) {
  $(e.target).addClass('screenreader-only')
  return this.$el.find('iframe').removeClass('info_alert_outline')
}

// Internal: Create collaboration edit form HTML.
//
// options - A hash of options used to configure the template:
//           :action    - The URL to post the form to.
//           :className - A string of CSS classes to add to the form.
//           :data      - A hash of TemplateData to apply to the form fields.
//
// Returns a jQuery object form.
CollaborationView.prototype.formTemplate = function (arg) {
  const action = arg.action
  const data = arg.data
  const $form = $(
    editForm(
      extend(data, {
        action,
        id: this.id,
      })
    )
  )
  return $form.on(
    'keydown',
    (function (_this) {
      return function (e) {
        if (e.which === 27) {
          e.preventDefault()
          return _this.onCloseForm(e)
        }
      }
    })(this)
  )
}

CollaborationView.prototype.iframeTemplate = function (arg) {
  const url = arg.url
  const $iframe = $(
    editIframe({
      id: this.id,
      url,
      allowances: iframeAllowances(),
    })
  )
  return $iframe.on(
    'keydown',
    (function (_this) {
      return function (e) {
        if (e.which === 27) {
          e.preventDefault()
          return _this.onCloseForm(e)
        }
      }
    })(this)
  )
}

// Internal: Confirm deleting of a Google Docs collaboration.
//
// Returns nothing.
CollaborationView.prototype.confirmGoogleDocsDelete = function () {
  const $dialog = $('#delete_collaboration_dialog').data('collaboration', this.$el)
  return $dialog.dialog({
    title: I18n.t('titles.delete', 'Delete collaboration?'),
    width: 350,
    modal: true,
    zIndex: 1000,
  })
}

// Internal: Confirm deleting a non-Google Docs collaboration.
//
// url - The URL to post the delete request to.
//
// Returns nothing.
CollaborationView.prototype.confirmDelete = function (url) {
  return this.$el.confirmDelete({
    message: I18n.t('collaboration.delete', 'Are you sure you want to delete this collaboration?'),
    success: this.delete,
    url,
  })
}

CollaborationView.prototype.delete = function () {
  $.screenReaderFlashMessage(I18n.t('Collaboration was deleted'))
  this.$el.slideUp(
    (function (_this) {
      return function () {
        return _this.$el.remove()
      }
    })(this)
  )
  this.trigger('delete', this)
  const otherDeleteLinks = $('.delete_collaboration_link').toArray()
  const curDeleteLink = this.$el.find('.delete_collaboration_link')[0]
  const newIndex = otherDeleteLinks.indexOf(curDeleteLink)
  if (newIndex > 0) {
    return otherDeleteLinks[newIndex - 1].focus()
  } else {
    return $('.add_collaboration_link').focus()
  }
}

// Internal: Hide collaboration and display an edit form.
//
// e - Event object.
//
// Returns nothing.
CollaborationView.prototype.onEdit = function (e) {
  let $form, $iframe
  e.preventDefault()
  if (this.$el.attr('data-update-launch-url')) {
    $iframe = this.iframeTemplate({
      url: this.$el.attr('data-update-launch-url'),
    })
    this.$el.children().hide()
    return this.$el.append($iframe)
  } else {
    $form = this.formTemplate({
      action: $(e.currentTarget).attr('href'),
      className: this.$el.attr('class'),
      data: this.$el.getTemplateData({
        textValues: ['title', 'description'],
      }),
    })
    this.$el.children().hide()
    this.$el.append($form)
    this.addCollaboratorPicker($form)
    return $form.find('[name="collaboration[title]"]').focus()
  }
}

// Internal: Delete the collaboration.
//
// e - Event object.
//
// Returns nothing.
CollaborationView.prototype.onDelete = function (e) {
  e.preventDefault()
  const href = $(e.currentTarget).attr('href')
  if (this.$el.hasClass('google_docs')) {
    return this.confirmGoogleDocsDelete()
  } else {
    return this.confirmDelete(href)
  }
}

// Internal: Hide the edit form and display the show content.
//
// e - Event object.
//
// Returns nothing.
CollaborationView.prototype.onCloseForm = function (_e) {
  this.$el.find('form').remove()
  this.$el.children().show()
  return this.$el.find('.edit_collaboration_link').focus()
}

CollaborationView.prototype.addCollaboratorPicker = function ($form) {
  const view = new CollaboratorPickerView({
    edit: true,
    el: $form.find('.collaborator_list'),
    id: this.id,
  })
  return view.render()
}

export default CollaborationView
