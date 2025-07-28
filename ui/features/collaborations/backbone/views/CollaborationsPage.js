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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, reject} from 'lodash'
import {View} from '@canvas/backbone'
import CollaborationView from './CollaborationView'
import CollaborationFormView from './CollaborationFormView'

const I18n = createI18nScope('collaborations')

extend(CollaborationsPage, View)

function CollaborationsPage() {
  this.onFormValidate = this.onFormValidate.bind(this)
  this.onFormHide = this.onFormHide.bind(this)
  this.onCollaborationDelete = this.onCollaborationDelete.bind(this)
  this.initPageState = this.initPageState.bind(this)
  return CollaborationsPage.__super__.constructor.apply(this, arguments)
}

CollaborationsPage.prototype.events = {
  'click .add_collaboration_link': 'addCollaboration',
  'keyclick .add_collaboration_link': 'addCollaboration',
}

CollaborationsPage.prototype.initialize = function () {
  CollaborationsPage.__super__.initialize.apply(this, arguments)
  this.cacheElements()
  this.createViews()
  return this.attachEvents()
}

// Internal: Set up page state on load.
//
// Returns nothing.
CollaborationsPage.prototype.initPageState = function () {
  if ($('#collaborations .collaboration:visible').length === 0) {
    this.addFormView.render(false)
    return this.$addLink.hide()
  }
}

CollaborationsPage.prototype.cacheElements = function () {
  this.$addLink = $('.add_collaboration_link')
  this.$addForm = $('#new_collaboration')
  return (this.$noCollaborationsMessage = $('#no_collaborations_message'))
}

CollaborationsPage.prototype.createViews = function () {
  this.addFormView = new CollaborationFormView({
    el: this.$addForm,
  })
  return (this.collaborationViews = $('div.collaboration').map(function () {
    return new CollaborationView({
      el: $(this),
    })
  }))
}

CollaborationsPage.prototype.attachEvents = function () {
  this.addFormView.on('hide', this.onFormHide).on('validate', this.onFormValidate)
  each(
    this.collaborationViews,
    (function (_this) {
      return function (view) {
        return view.on('delete', _this.onCollaborationDelete).on('validate', _this.onFormValidate)
      }
    })(this),
  )
}

CollaborationsPage.prototype.addCollaboration = function (e) {
  e.preventDefault()
  this.$addLink.hide()
  this.addFormView.render()
  return this.$el.scrollTo(this.addFormView.$el)
}

CollaborationsPage.prototype.onCollaborationDelete = function (deletedView) {
  this.collaborationViews = reject(this.collaborationViews, function (view) {
    return view === deletedView
  })
  if (this.collaborationViews.length === 0) {
    this.$noCollaborationsMessage.show()
    return this.addFormView.render(false)
  }
}

CollaborationsPage.prototype.onFormHide = function () {
  this.$addLink.show()
  return this.$addLink.focus()
}

CollaborationsPage.prototype.onFormValidate = function (e, $form, collaborationId) {
  let formValid = true
  const data = $form.getFormData()
  const titleInputId = collaborationId ? `collaboration_${collaborationId}_title` : 'collaboration_title'
  const $titleInput = $form.find(`#${titleInputId}`)
  if (!data['collaboration[title]']) {
    $titleInput.focus().errorBox(I18n.t('Please add a document name'))
    formValid = false
  }
  if (ENV.TITLE_MAX_LEN && data['collaboration[title]'].length > ENV.TITLE_MAX_LEN) {
    $titleInput.focus().errorBox(
      I18n.t('errors.title_too_long',
        'Please use %{maxLength} characters or less for the name. Use the description for additional content.',
        {maxLength: ENV.TITLE_MAX_LEN}
      )
    )
    formValid = false
  }

  if (!formValid) {
    e.preventDefault()
    e.stopPropagation()
  } else if (!collaborationId) {
    setTimeout(function () {
      return (window.location = window.location.pathname)
    }, 2500)
  }
}

export default CollaborationsPage
