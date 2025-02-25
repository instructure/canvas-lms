/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import React from 'react'
import {createRoot} from 'react-dom/client'
import round from '@canvas/round'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, extend as lodashExtend} from 'lodash'
import numberHelper from '@canvas/i18n/numberHelper'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import NeverDropCollection from '../collections/NeverDropCollection'
import NeverDropCollectionView from './NeverDropCollectionView'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import GroupRuleInput from '../../react/GroupRuleInput'
import DialogFormView, {
  isSmallTablet,
  getResponsiveWidth,
} from '@canvas/forms/backbone/views/DialogFormView'
import template from '../../jst/CreateGroup.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'
import '@canvas/rails-flash-notifications'

const I18n = createI18nScope('CreateGroupView')

const SHORT_HEIGHT = 250
const AG_FIELDS = {
  NAME: 'name',
  GROUP_WEIGHT: 'group_weight',
  DROP_RULES: {
    LOWEST: 'rules[drop_lowest]',
    HIGHEST: 'rules[drop_highest]'
  }
}

class CreateGroupView extends DialogFormView {
  initialize() {
    this.errorRoots = {}
    this.dropLowestRoot = null
    this.dropHighestRoot = null
    super.initialize(...arguments)
    // this.assignmentGroup will be defined when editing
    return (this.model = this.assignmentGroup || new AssignmentGroup({assignments: []}))
  }

  getFieldSelector(field) {
    const fields = {
      [AG_FIELDS.NAME]: `ag_${this.assignmentGroup?.id ?? 'new'}_name`,
      [AG_FIELDS.GROUP_WEIGHT]: `ag_${this.assignmentGroup?.id ?? 'new'}_group_weight`
    }
    if (this.assignmentGroup) {
      fields[AG_FIELDS.DROP_RULES.LOWEST] = `ag_${this.assignmentGroup.id}_drop_lowest`,
      fields[AG_FIELDS.DROP_RULES.HIGHEST] = `ag_${this.assignmentGroup.id}_drop_highest`
    }
    return fields[field]
  }

  getElement(selector) {
    // We need to query for all elements with the given selector and return the last one.
    // This is because once the form has been submitted, if the user reopens the dialog
    // it will create a new dialog in the DOM.
    const allElements = document.querySelectorAll(selector)
    if (allElements.length > 0) {
      return allElements[allElements.length - 1]
    }
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
      this.dropLowestRoot?.unmount()
      this.dropLowestRoot = null
      this.dropHighestRoot?.unmount()
      this.dropHighestRoot = null
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
    if (data.group_weight) {
      data.group_weight = round(numberHelper.parse(data.group_weight), 2)
    }
    return data
  }

  validateName(value = null, shouldShowError = true) {
    const inputValue = value ?? this.getElement('#' + this.getFieldSelector(AG_FIELDS.NAME))?.value
    if (inputValue.length > 255) {
      if (shouldShowError) {
        this.showInputError(AG_FIELDS.NAME, this.messages.name_too_long_error)
      } else {
        return [{type: 'name_too_long_error', message: this.messages.name_too_long_error}]
      }
    } else if (inputValue === '') {
      if (shouldShowError) {
        this.showInputError(AG_FIELDS.NAME, this.messages.no_name_error)
      } else {
        return [{type: 'no_name_error', message: this.messages.no_name_error}]
      }
    }
  }

  validateGroupWeight(value = null, shouldShowError = true) {
    const inputValue = value ?? this.getElement('#' + this.getFieldSelector(AG_FIELDS.GROUP_WEIGHT))?.value
    if (![undefined, null, ''].includes(inputValue) && Number.isNaN(Number(numberHelper.parse(inputValue)))) {
      if (shouldShowError) {
        this.showInputError(AG_FIELDS.GROUP_WEIGHT, this.messages.non_number)
      } else {
        return [{type: 'number', message: this.messages.non_number}]
      }
    }
  }

  validateRules(field, value = null, shouldShowError = true) {
    let inputValue = value ?? this.getElement('#' + this.getFieldSelector(field))?.value
    if (inputValue === '') {
      return
    } else {
      inputValue = numberHelper.parse(inputValue)
    }

    let errorMessage
    let errorType
    let max = 0
    if (this.assignmentGroup) {
      const as = this.assignmentGroup.get('assignments')
      if (as != null) {
        max = as.size()
      }
    }

    if (Number.isNaN(Number(inputValue))) {
      errorType = 'number'
      errorMessage = this.messages.non_number
    } else if (!Number.isInteger(inputValue)) {
      errorType = 'integer'
      errorMessage = this.messages.non_integer
    } else if (inputValue < 0) {
      errorType = 'positive_number'
      errorMessage = this.messages.positive_number
    } else if (inputValue > max) {
      errorType = 'maximum'
      errorMessage = this.messages.max_number
    }

    if (errorMessage) {
      if (shouldShowError) {
        this.showInputError(field, errorMessage)
      } else {
        return [{type: errorType, message: errorMessage}]
      }
    }
  }

  validateInput(e) {
    switch (e.target.name) {
      case AG_FIELDS.NAME:
        this.validateName()
        break
      case AG_FIELDS.GROUP_WEIGHT:
        this.validateGroupWeight()
        break
      case AG_FIELDS.DROP_RULES.LOWEST:
        this.validateRules(AG_FIELDS.DROP_RULES.LOWEST)
        break
      case AG_FIELDS.DROP_RULES.HIGHEST:
        this.validateRules(AG_FIELDS.DROP_RULES.HIGHEST)
        break
      default:
        break
    }
  }

  validateFormData(data) {
    const errors = {}
    const nameErrors = this.validateName(data.name, false)
    const weightErrors = this.validateGroupWeight(data.group_weight, false)
    if (nameErrors) {
      errors[AG_FIELDS.NAME] = nameErrors
    }

    if (weightErrors) {
      errors[AG_FIELDS.GROUP_WEIGHT] = weightErrors
    }

    each(data.rules, (value, name) => {
      // don't want to validate the never_drop field
      if (name === 'never_drop') {
        return
      }
      const field = `rules[${name}]`
      const rulesErrors = this.validateRules(field, value, false)
      if (rulesErrors) {
        errors[field] = rulesErrors
      }
    })
    return errors
  }

  isDropInput(inputField) {
    return [AG_FIELDS.DROP_RULES.LOWEST, AG_FIELDS.DROP_RULES.HIGHEST].includes(inputField)
  }

  showInputError(field, message) {
    const fieldSelector = this.getFieldSelector(field)
    const selector = this.isDropInput(field) ? `.${fieldSelector}_container` : `#${fieldSelector}`
    const container = this.getElement(selector)
    if (container) {
      container.classList.add('error-outline')
      container.setAttribute('aria-label', message)
    }
    const errorsContainer = this.getElement(`#${fieldSelector}_errors`)
    if (errorsContainer) {
      const root = this.errorRoots[field] ?? createRoot(errorsContainer)
      root.render(
        <FormattedErrorMessage
          message={message}
          margin={"x-small 0 0 0"}
        />
      )
      this.errorRoots[field] = root
    }
  }

  showErrors(errors) {
    if (Object.keys(errors).length > 0) {
      let shouldFocus = true
      Object.entries(errors).forEach(([inputField, errors]) => {
        this.showInputError(inputField, errors[0].message)
        // focus the first error
        if (shouldFocus) {
          this.getElement('#' + inputField)?.focus()
          shouldFocus = false
        }
      })
    }
  }

  hideErrors(field) {
    const fieldSelector = this.getFieldSelector(field)
    const selector = this.isDropInput(field) ? `.${fieldSelector}_container` : `#${fieldSelector}`
    const container = this.getElement(selector)
    container?.classList.remove('error-outline')
    container?.removeAttribute('aria-label')
    this.errorRoots[field]?.unmount()
    delete this.errorRoots[field]
  }

  clearInputErrors(e) {
    this.hideErrors(e.target.name)
  }

  clearAllErrors() {
    Object.keys(this.errorRoots).forEach((inputField) => this.hideErrors(inputField))
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
      number_input: 'text',
      small_tablet: isSmallTablet,
    })
  }

  openAgain() {
    if (this.model.get('assignments').length === 0 && this.model.get('id') === undefined) {
      this.setDimensions(this.defaults.width, SHORT_HEIGHT)
    }

    super.openAgain(...arguments)
    if (this.assignmentGroup) {
      const dropLowestContainer = this.getElement(`.ag_${this.assignmentGroup.id}_drop_lowest_container`)
      this.dropLowestRoot = this.dropLowestRoot ?? createRoot(dropLowestContainer)
      this.dropLowestRoot.render(
        <GroupRuleInput
          groupId={this.assignmentGroup.id}
          type={'drop_lowest'}
          onBlur={() => this.validateRules(AG_FIELDS.DROP_RULES.LOWEST)}
          initialValue={dropLowestContainer?.dataset.value}
          onChange={() => this.hideErrors(AG_FIELDS.DROP_RULES.LOWEST)}
          data-testid={'drop_lowest_input'}
        />
      )
      const dropHighestContainer = this.getElement(`.ag_${this.assignmentGroup.id}_drop_highest_container`)
      this.dropHighestRoot = this.dropHighestRoot ?? createRoot(dropHighestContainer)
      this.dropHighestRoot.render(
        <GroupRuleInput
          groupId={this.assignmentGroup.id}
          type={'drop_highest'}
          onBlur={() => this.validateRules(AG_FIELDS.DROP_RULES.HIGHEST)}
          initialValue={dropHighestContainer?.dataset.value}
          onChange={() => this.hideErrors(AG_FIELDS.DROP_RULES.HIGHEST)}
          data-testid={'drop_highest_input'}
        />
      )
    }
    this.checkGroupWeight()
    return this.getNeverDrops()
  }

  close() {
    this.clearAllErrors()
    this.dropLowestRoot?.unmount()
    this.dropLowestRoot = null
    this.dropHighestRoot?.unmount()
    this.dropHighestRoot = null
    super.close(...arguments)
  }
}

CreateGroupView.prototype.defaults = {
  width: getResponsiveWidth(320, 550),
  height: 500,
}

CreateGroupView.prototype.events = lodashExtend({}, CreateGroupView.prototype.events, {
  'click .dialog_closer': 'close',
  'blur .group_weight': 'roundWeight',
  'input [name="name"]': 'clearInputErrors',
  'change [name="name"]': 'validateInput',
  'input [name="group_weight"]': 'clearInputErrors',
  'change [name="group_weight"]': 'validateInput'
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
  },
)

export default CreateGroupView
