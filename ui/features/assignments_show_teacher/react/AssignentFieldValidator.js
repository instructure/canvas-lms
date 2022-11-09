/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

const I18n = useI18nScope('assignments_2')

export default class AssignmentFieldValidator {
  messages = {}

  isPointsValid = value => {
    const strValue = `${value}`
    if (!strValue) {
      this.messages.pointsPossible = I18n.t('Points is required')
      return false // it's required
    }
    if (Number.isNaN(Number(strValue))) {
      this.messages.pointsPossible = I18n.t('Points must be a number >= 0')
      return false // must be a number
    }
    if (parseFloat(strValue) < 0) {
      // must be non-negative
      this.messages.pointsPossible = I18n.t('Points must >= 0')
      return false
    }
    delete this.messages.pointsPossible
    return true
  }

  isNameValid = value => {
    if (!value || value.trim().length === 0) {
      this.messages.name = I18n.t('Assignment name is required')
      return false
    }
    delete this.messages.name
    return true
  }

  // the raw date-time value is invalid
  // set an appropriate error message
  getInvalidDateTimeMessage = ({rawDateValue, rawTimeValue}) => {
    let msg
    if (rawDateValue) {
      msg = I18n.t('The date is not valid.', {value: rawDateValue})
    } else if (rawTimeValue) {
      msg = I18n.t('You must provide a date with a time.')
    } else {
      msg = I18n.t('Invalid date or time')
    }
    return msg
  }

  // A note on the date cross-field validators.
  // Though we want error messages specific to the field being edited,
  // we only want one at a time to be logged.
  // So if date A fails in comparison to B, we set A's error message
  // and clear B's
  isDueAtValid = (value, path, context) => {
    let isValid = true
    if (value && typeof value === 'object') {
      this.messages[path] = this.getInvalidDateTimeMessage(value)
      isValid = false
    } else {
      if (value && context.unlockAt) {
        if (value < context.unlockAt) {
          this.messages[path] = I18n.t('Due date must be after the Available date')
          isValid = false
        }
      }
      if (value && context.lockAt) {
        if (value > context.lockAt) {
          this.messages[path] = I18n.t('Due date must be before the Until date')
          isValid = false
        }
      }
    }
    if (isValid) {
      delete this.messages[path]
    } else {
      delete this.messages[path.replace('dueAt', 'unlockAt')]
      delete this.messages[path.replace('dueAt', 'lockAt')]
    }
    return isValid
  }

  isUnlockAtValid = (value, path, context) => {
    let isValid = true
    if (value && typeof value === 'object') {
      this.messages[path] = this.getInvalidDateTimeMessage(value)
      isValid = false
    } else {
      if (value && context.dueAt) {
        if (value > context.dueAt) {
          this.messages[path] = I18n.t('Available date must be before the Due date')
          isValid = false
        }
      }
      if (value && context.lockAt) {
        if (value > context.lockAt) {
          this.messages[path] = I18n.t('Available date must be before the Until date')
          isValid = false
        }
      }
    }
    if (isValid) {
      delete this.messages[path]
    } else {
      delete this.messages[path.replace('unlockAt', 'dueAt')]
      delete this.messages[path.replace('unlockAt', 'lockAt')]
    }
    return isValid
  }

  isLockAtValid = (value, path, context) => {
    let isValid = true
    if (value && typeof value === 'object') {
      this.messages[path] = this.getInvalidDateTimeMessage(value)
      isValid = false
    } else {
      if (value && context.dueAt) {
        if (value < context.dueAt) {
          this.messages[path] = I18n.t('Until date must be after the Due date')
          isValid = false
        }
      }
      if (value && context.unlockAt) {
        if (value < context.unlockAt) {
          this.messages[path] = I18n.t('Until date must be after the Available date')
          isValid = false
        }
      }
    }
    if (isValid) {
      delete this.messages[path]
    } else {
      delete this.messages[path.replace('lockAt', 'dueAt')]
      delete this.messages[path.replace('lockAt', 'unlockAt')]
    }
    return isValid
  }

  validators = {
    pointsPossible: this.isPointsValid,
    name: this.isNameValid,
    dueAt: this.isDueAtValid,
    unlockAt: this.isUnlockAtValid,
    lockAt: this.isLockAtValid,
  }

  invalidFields = () => this.messages

  validate = (path, value, context) => {
    const validationPath = path.replace(/.*\./, '')
    return this.validators[validationPath]
      ? this.validators[validationPath](value, path, context)
      : true
  }

  errorMessage = path => this.messages[path]
}
