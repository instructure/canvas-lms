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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {extend as lodashExtend} from 'lodash'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import assignmentSyncSettingsTemplate from '../../jst/AssignmentSyncSettings.handlebars'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('AssignmentSyncSettingsView')

extend(AssignmentSyncSettingsView, DialogFormView)

function AssignmentSyncSettingsView() {
  return AssignmentSyncSettingsView.__super__.constructor.apply(this, arguments)
}

AssignmentSyncSettingsView.prototype.template = assignmentSyncSettingsTemplate

AssignmentSyncSettingsView.prototype.wrapperTemplate = wrapper

AssignmentSyncSettingsView.prototype.defaults = {
  width: 600,
  height: 300,
  collapsedHeight: 300,
}

AssignmentSyncSettingsView.prototype.events = lodashExtend(
  {},
  AssignmentSyncSettingsView.prototype.events,
  {
    'click .dialog_closer': 'cancel',
  }
)

AssignmentSyncSettingsView.optionProperty('viewToggle')

AssignmentSyncSettingsView.optionProperty('sisName')

AssignmentSyncSettingsView.prototype.initialize = function () {
  this.viewToggle = false
  return AssignmentSyncSettingsView.__super__.initialize.apply(this, arguments)
}

AssignmentSyncSettingsView.prototype.openDisableSync = function () {
  if (this.viewToggle) {
    return this.openAgain()
  } else {
    this.viewToggle = true
    return this.open()
  }
}

AssignmentSyncSettingsView.prototype.currentGradingPeriod = function () {
  const selected_id = $('#grading_period_selector').children(':selected').attr('id')
  const id = selected_id === void 0 ? '' : selected_id.split('_').pop()
  return id
}

AssignmentSyncSettingsView.prototype.submit = function (event) {
  if (event != null) {
    event.preventDefault()
  }
  const success_message = I18n.t('Sync to %{name} successfully disabled', {
    name: this.sisName,
  })
  const error_message = I18n.t('Disabling Sync to %{name} failed', {
    name: this.sisName,
  })
  return $.ajaxJSON(
    '/api/sis/courses/' + this.model.id + '/disable_post_to_sis',
    'PUT',
    {
      grading_period_id: this.currentGradingPeriod(),
    },
    function (_data) {
      $.flashMessage(success_message)
      return setTimeout(window.location.reload(true))
    },
    function () {
      return $.flashError(error_message)
    }
  )
}

AssignmentSyncSettingsView.prototype.cancel = function () {
  return this.close()
}

AssignmentSyncSettingsView.prototype.toJSON = function () {
  const data = AssignmentSyncSettingsView.__super__.toJSON.apply(this, arguments)
  data.sisName = this.sisName
  return data
}

export default AssignmentSyncSettingsView
