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

/* eslint-disable object-shorthand */

import {extend} from '@canvas/backbone/utils'
import {extend as lodashExtend} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import template from '../../jst/DeleteGroup.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

const I18n = useI18nScope('DeleteGroupView')

extend(DeleteGroupView, DialogFormView)

function DeleteGroupView() {
  this.removeFromGroupOptions = this.removeFromGroupOptions.bind(this)
  this.addToGroupOptions = this.addToGroupOptions.bind(this)
  this.updateAssignmentCount = this.updateAssignmentCount.bind(this)
  return DeleteGroupView.__super__.constructor.apply(this, arguments)
}

DeleteGroupView.prototype.defaults = shimGetterShorthand(
  {
    width: 500,
    height: 350,
  },
  {
    title: function () {
      return I18n.t('Delete Assignment Group')
    },
  }
)

DeleteGroupView.prototype.els = {
  '.assignment_count': '$assignmentCount',
  '.group_select': '$groupSelect',
}

DeleteGroupView.prototype.events = lodashExtend({}, DeleteGroupView.prototype.events, {
  'click .dialog_closer': 'close',
  'change .group_select': 'selectMove',
})

DeleteGroupView.prototype.template = template

DeleteGroupView.prototype.wrapperTemplate = wrapper

DeleteGroupView.prototype.initialize = function () {
  DeleteGroupView.__super__.initialize.apply(this, arguments)
  this.model.get('assignments').on('add remove', this.updateAssignmentCount)
  this.model.collection.on('add', this.addToGroupOptions)
  return this.model.collection.on('remove', this.removeFromGroupOptions)
}

DeleteGroupView.prototype.toJSON = function () {
  const data = DeleteGroupView.__super__.toJSON.apply(this, arguments)
  const groups = this.model.collection.reject(
    (function (_this) {
      return function (model) {
        return model.get('id') === _this.model.get('id')
      }
    })(this)
  )
  const groups_json = groups.map(function (model) {
    return model.toJSON()
  })
  return lodashExtend(data, {
    assignment_count: this.model.get('assignments').length,
    groups: groups_json,
    label_id: data.id,
  })
}

DeleteGroupView.prototype.updateAssignmentCount = function () {
  return this.$assignmentCount.text(this.model.get('assignments').length)
}

DeleteGroupView.prototype.addToGroupOptions = function (model) {
  const id = model.get('id')
  const $opt = $('<option>')
  $opt.val(id)
  $opt.addClass('ag_' + id)
  $opt.text(model.get('name'))
  return this.$groupSelect.append($opt)
}

DeleteGroupView.prototype.removeFromGroupOptions = function (model) {
  const id = model.get('id')
  return this.$groupSelect.find('move_to_ag_' + id).remove()
}

DeleteGroupView.prototype.validateFormData = function (data) {
  const errors = {}
  if (data.action === 'move' && !data.move_assignments_to) {
    errors.move_assignments_to = [
      {
        type: 'required',
        message: I18n.t('You must select an assignment group.'),
      },
    ]
  }
  return errors
}

DeleteGroupView.prototype.saveFormData = function (data) {
  if (data.action === 'move' && data.move_assignments_to) {
    return this.destroyModel(data.move_assignments_to)
  } else if (data.action === 'delete') {
    return this.destroyModel()
  }
}

DeleteGroupView.prototype.destroyModel = function (moveTo) {
  if (moveTo == null) {
    moveTo = null
  }
  this.collection = this.model.collection
  const data = moveTo ? 'move_assignments_to=' + moveTo : ''
  const destroyDfd = this.model.destroy({
    data: data,
    wait: true,
  })
  // eslint-disable-next-line promise/catch-or-return
  destroyDfd.then(
    (function (_this) {
      return function () {
        if (moveTo) {
          return _this.collection.fetch({
            reset: true,
          })
        }
      }
    })(this)
  )
  this.$el.disableWhileLoading(destroyDfd)
  return destroyDfd
}

DeleteGroupView.prototype.selectMove = function () {
  if (!this.$el.find('.group_select :selected').hasClass('blank')) {
    return this.$el.find('.assignment_group_move').prop('checked', true)
  }
}

DeleteGroupView.prototype.openAgain = function () {
  if (this.model.collection.models.length > 1) {
    if (this.model.get('assignments').length > 0) {
      return DeleteGroupView.__super__.openAgain.apply(this, arguments)
    } else if (
      // eslint-disable-next-line no-alert
      window.confirm(
        I18n.t('confirm_delete_group', 'Are you sure you want to delete this Assignment Group?')
      )
    ) {
      return this.destroyModel()
    }
  } else {
    // eslint-disable-next-line no-alert
    return window.alert(
      I18n.t('cannot_delete_group', 'You must have at least one Assignment Group')
    )
  }
}

export default DeleteGroupView
