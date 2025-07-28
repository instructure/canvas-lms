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
import {View} from '@canvas/backbone'
import CollaboratorPickerView from './CollaboratorPickerView'

extend(CollaborationFormView, View)

function CollaborationFormView() {
  return CollaborationFormView.__super__.constructor.apply(this, arguments)
}

CollaborationFormView.prototype.events = {
  submit: 'onSubmit',
  'click .cancel_button': 'onCancel',
  keydown: 'onKeydown',
}

CollaborationFormView.prototype.initialize = function () {
  CollaborationFormView.__super__.initialize.apply(this, arguments)
  this.cacheElements()
  this.picker = new CollaboratorPickerView({
    el: this.$collaborators,
  })
}

CollaborationFormView.prototype.cacheElements = function () {
  this.$titleInput = this.$el.find('#collaboration_title')
  return (this.$collaborators = this.$el.find('.collaborator_list'))
}

CollaborationFormView.prototype.render = function (focus) {
  if (focus == null) {
    focus = true
  }
  this.$el.show()
  if (focus) {
    this.$el.find('[name="collaboration[collaboration_type]"]').focus()
  }
  if (this.$collaborators.is(':empty')) {
    this.picker.render()
  }
  return this
}

CollaborationFormView.prototype.onSubmit = function (e) {
  this.trigger('validate', e, this.$el)
}

CollaborationFormView.prototype.onCancel = function (e) {
  e.preventDefault()
  this.$el.hide()
  return this.trigger('hide')
}

CollaborationFormView.prototype.onKeydown = function (e) {
  if (e.which === 27) {
    return this.onCancel(e)
  }
}

export default CollaborationFormView
