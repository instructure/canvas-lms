//
// Copyright (C) 2013 - present Instructure, Inc.
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

import round from '@canvas/round'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, extend as lodashExtend} from 'lodash'
import numberHelper from '@canvas/i18n/numberHelper'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import NeverDropCollection from '../collections/NeverDropCollection'
import NeverDropCollectionView from './NeverDropCollectionView'
import DialogFormView, {
  isSmallTablet,
  getResponsiveWidth,
} from '@canvas/forms/backbone/views/DialogFormView'
import template from '../../jst/CreateGroup.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('CreateGroupView')

const SHORT_HEIGHT = 250
class CreateGroupView extends DialogFormView {
  initialize() {
    super.initialize(...arguments)
    // this.assignmentGroup will be defined when editing
    return (this.model = this.assignmentGroup || new AssignmentGroup({assignments: []}))
  }

  onSaveSuccess() {
    super.onSaveSuccess(...arguments)
    // meaning we are editing
    if (this.assignmentGroup) {
      // trigger instead of calling render directly
      this.model.collection.trigger('render', this.model.collection)
    } else {
      this.assignmentGroups.add(this.model)
      this.model = new AssignmentGroup({assignments: []})

      this.render()
    }

    // we do this here because the re-render above causes the default focus
    // from DialogFormView not to stick
    return setTimeout(() => {
      $.flashMessage(I18n.t('Assignment group was saved successfully'))
      return this.focusReturnsTo()?.focus()
    }, 0)
  }

  getFormData() {
    const data = super.getFormData(...arguments)
    if (data.rules) {
      if (['', '0'].includes(data.rules.drop_lowest)) {
        delete data.rules.drop_lowest
      }
      if (['', '0'].includes(data.rules.drop_highest)) {
        delete data.rules.drop_highest
      }
      if (data.rules.never_drop?.length === 0) {
        delete data.rules.never_drop
      }
    }
    data.group_weight = round(numberHelper.parse(data.group_weight), 2)
    return data
  }

  validateFormData(data) {
    let max = 0
    if (this.assignmentGroup) {
      const as = this.assignmentGroup.get('assignments')
      if (as != null) {
        max = as.size()
      }
    }
    const errors = {}
    if (data.name.length > 255) {
      errors.name = [{type: 'name_too_long_error', message: this.messages.name_too_long_error}]
    }
    if (data.name === '') {
      errors.name = [{type: 'no_name_error', message: this.messages.no_name_error}]
    }
    if (data.group_weight && Number.isNaN(Number(numberHelper.parse(data.group_weight)))) {
      errors.group_weight = [{type: 'number', message: this.messages.non_number}]
    }
    each(data.rules, (value, name) => {
      // don't want to validate the never_drop field
      if (name === 'never_drop') {
        return
      }
      const val = numberHelper.parse(value)
      const field = `rules[${name}]`
      if (Number.isNaN(Number(val))) {
        errors[field] = [{type: 'number', message: this.messages.non_number}]
      }
      if (!Number.isInteger(val)) {
        errors[field] = [{type: 'integer', message: this.messages.non_integer}]
      }
      if (val < 0) {
        errors[field] = [{type: 'positive_number', message: this.messages.positive_number}]
      }
      if (val > max) {
        return (errors[field] = [{type: 'maximum', message: this.messages.max_number}])
      }
    })
    return errors
  }

  showWeight() {
    const course = this.course || this.model.collection?.course
    return course?.get('apply_assignment_group_weights')
  }

  canChangeWeighting() {
    return this.userIsAdmin || !this.model.anyAssignmentInClosedGradingPeriod()
  }

  checkGroupWeight() {
    if (this.showWeight() && this.canChangeWeighting()) {
      return this.$el.find('.group_weight').removeAttr('readonly', 'aria-disabled')
    } else {
      return this.$el.find('.group_weight').attr('readonly', 'readonly').attr('aria-disabled', true)
    }
  }

  getNeverDrops() {
    this.$neverDropContainer.empty()
    const rules = this.model.rules()
    this.never_drops = new NeverDropCollection([], {
      assignments: this.model.get('assignments'),
      ag_id: this.model.get('id') || 'new',
    })

    this.ndCollectionView = new NeverDropCollectionView({
      canChangeDropRules: this.canChangeWeighting(),
      collection: this.never_drops,
    })

    this.$neverDropContainer.append(this.ndCollectionView.render().el)
    if (rules && rules.never_drop) {
      return this.never_drops.reset(rules.never_drop, {parse: true})
    }
  }

  roundWeight(e) {
    const value = $(e.target).val()
    const rounded_value = round(numberHelper.parse(value), 2)
    if (Number.isNaN(Number(rounded_value))) {
      //
    } else {
      return $(e.target).val(I18n.n(rounded_value))
    }
  }

  toJSON() {
    const data = this.model.toJSON()
    return lodashExtend(data, {
      show_weight: this.showWeight(),
      can_change_weighting: this.canChangeWeighting(),
      group_weight: this.showWeight() ? data.group_weight : null,
      label_id: this.model.get('id') || 'new',
      drop_lowest: this.model.rules()?.drop_lowest || 0,
      drop_highest: this.model.rules()?.drop_highest || 0,
      editable_drop: this.model.get('assignments').length > 0 || this.model.get('id'),
      // Safari is not fully compatiable with html5 validation - needs to be set to text instead to ensure our validations work
      number_input: navigator.userAgent.match(/Version\/[\d\.]+.*Safari/) ? 'text' : 'number',
      small_tablet: isSmallTablet,
    })
  }

  openAgain() {
    if (this.model.get('assignments').length === 0 && this.model.get('id') === undefined) {
      this.setDimensions(this.defaults.width, SHORT_HEIGHT)
    }

    super.openAgain(...arguments)
    this.checkGroupWeight()
    return this.getNeverDrops()
  }
}

CreateGroupView.prototype.defaults = {
  width: getResponsiveWidth(320, 550),
  height: 500,
}

CreateGroupView.prototype.events = lodashExtend({}, CreateGroupView.prototype.events, {
  'click .dialog_closer': 'close',
  'blur .group_weight': 'roundWeight',
})

CreateGroupView.prototype.els = {'.never_drop_rules_group': '$neverDropContainer'}

CreateGroupView.prototype.template = template
CreateGroupView.prototype.wrapperTemplate = wrapper

CreateGroupView.optionProperty('assignmentGroups')
CreateGroupView.optionProperty('assignmentGroup')
CreateGroupView.optionProperty('course')
CreateGroupView.optionProperty('userIsAdmin')

CreateGroupView.prototype.messages = shimGetterShorthand(
  {},
  {
    non_number() {
      return I18n.t('You must use a number')
    },
    non_integer() {
      return I18n.t('You must use an integer')
    },
    positive_number() {
      return I18n.t('You must use a positive number')
    },
    max_number() {
      return I18n.t('You cannot use a number greater than the number of assignments')
    },
    no_name_error() {
      return I18n.t('A name is required')
    },
    name_too_long_error() {
      return I18n.t('Name is too long')
    },
  }
)

export default CreateGroupView
