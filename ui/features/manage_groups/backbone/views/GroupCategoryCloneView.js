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
import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import template from '../../jst/groupCategoryClone.handlebars'

const I18n = useI18nScope('groups')

extend(GroupCategoryCloneView, DialogFormView)

function GroupCategoryCloneView() {
  this.onSaveSuccess = this.onSaveSuccess.bind(this)
  return GroupCategoryCloneView.__super__.constructor.apply(this, arguments)
}

GroupCategoryCloneView.prototype.template = template

GroupCategoryCloneView.prototype.wrapperTemplate = wrapperTemplate

GroupCategoryCloneView.prototype.className = 'form-dialog group-category-clone'

GroupCategoryCloneView.prototype.cloneSuccess = false

GroupCategoryCloneView.prototype.changeGroups = false

GroupCategoryCloneView.prototype.defaults = {
  width: 520,
  height: 450,
  title: I18n.t('Clone Group Set'),
}

GroupCategoryCloneView.prototype.events = {
  ...DialogFormView.prototype.events,
  'click .dialog_closer': 'close',
  'click .clone-options-toggle': 'toggleCloneOptions',
}

GroupCategoryCloneView.prototype.openAgain = function () {
  this.cloneSuccess = false
  this.changeGroups = false
  GroupCategoryCloneView.__super__.openAgain.apply(this, arguments)
  this.render()
  return $('.ui-dialog-titlebar-close').focus()
}

GroupCategoryCloneView.prototype.toJSON = function () {
  const json = GroupCategoryCloneView.__super__.toJSON.apply(this, arguments)
  json.displayCautionOptions = this.options.openedFromCaution
  return json
}

GroupCategoryCloneView.prototype.toggleCloneOptions = function () {
  const cloneOption = this.$('input:radio[name=clone_option]:checked').val()
  if (cloneOption === 'clone') {
    this.$('.cloned_category_name_option').show()
    return this.$('.cloned_category_name_option').attr('aria-hidden', false)
  } else {
    this.$('.cloned_category_name_option').hide()
    return this.$('.cloned_category_name_option').attr('aria-hidden', true)
  }
}

GroupCategoryCloneView.prototype.submit = function (event) {
  event.preventDefault()
  const data = this.getFormData()
  if (data.clone_option === 'do_not_clone') {
    this.changeGroups = true
    return this.close()
  } else {
    return GroupCategoryCloneView.__super__.submit.call(this, event)
  }
}

GroupCategoryCloneView.prototype.saveFormData = function (data) {
  return this.model.cloneGroupCategoryWithName(data.name)
}

GroupCategoryCloneView.prototype.onSaveSuccess = function () {
  this.cloneSuccess = true
  return GroupCategoryCloneView.__super__.onSaveSuccess.apply(this, arguments)
}

export default GroupCategoryCloneView
