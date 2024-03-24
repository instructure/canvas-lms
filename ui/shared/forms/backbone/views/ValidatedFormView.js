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
import Backbone from '@canvas/backbone'
import ValidatedMixin from './ValidatedMixin'
import $ from 'jquery'
import {map, forEach, isEqual, includes, clone, isObject, chain, keys} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.toJSON'
import '@canvas/jquery/jquery.disableWhileLoading'
import '../../jquery/jquery.instructure_forms'
import {send} from '@canvas/rce-command-shim'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'
import sanitizeData from '../../sanitizeData'

const I18n = useI18nScope('errors')

const slice = [].slice

extend(ValidatedFormView, Backbone.View)

// Sets model data from a form, saves it, and displays errors returned in a
// failed request.
//
// @event submit
//
// @event fail
//   @signature `(errors, jqXHR, status, statusText)`
//   @param errors - the validation errors, each error has the form $input
//                   and the $errorBox attached to it for easy access
//
// @event success
//   @signature `(response, status, jqXHR)`
function ValidatedFormView() {
  this.checkUnload = this.checkUnload.bind(this)
  this.watchUnload = this.watchUnload.bind(this)
  this.onSaveFail = this.onSaveFail.bind(this)
  this.onSaveSuccess = this.onSaveSuccess.bind(this)
  return ValidatedFormView.__super__.constructor.apply(this, arguments)
}

ValidatedFormView.mixin(ValidatedMixin)

ValidatedFormView.prototype.tagName = 'form'

ValidatedFormView.prototype.className = 'validated-form-view'

ValidatedFormView.prototype.events = {
  submit: 'submit',
}

// Default options to pass when saving the model
ValidatedFormView.prototype.saveOpts = {
  // wait for server success response before updating model attributes locally
  wait: true,
}

// Default options to pass to disableWhileLoading when submitting
ValidatedFormView.prototype.disableWhileLoadingOpts = {}

// Sets the model data from the form and saves it. Called when the form
// submits, or can be called programatically.
// set @saveOpts in your view to to pass opts to Backbone.sync (like multipart: true if you have
// a file attachment).  if you want the form not to be re-enabled after save success (because you
// are navigating to a new page, set dontRenableAfterSaveSuccess to true on your view)
//
// NOTE: If you are uploading a file attachment, be careful! our
// syncWithMultipart extension doesn't call toJSON on your model!
//
// @api public
// @returns jqXHR
ValidatedFormView.prototype.submit = function (event, sendFunc) {
  let assignmentFieldErrors, dateOverrideErrors, disablingDfd, first_error, okayToContinue, saveDfd
  if (sendFunc == null) {
    sendFunc = send
  }
  if (event != null) {
    event.preventDefault()
  }
  this.hideErrors()
  const rceInputs = this.$el.find('textarea[data-rich_text]').toArray()
  okayToContinue = true
  // Indicate to the RCE that the page is closing.
  if (rceInputs.length > 0) {
    okayToContinue = rceInputs
      .map(
        (function (_this) {
          return function (rce) {
            return sendFunc($(rce), 'checkReadyToGetCode', window.confirm)
          }
        })(this)
      )
      .every(
        (function (_this) {
          return function (value) {
            return value
          }
        })(this)
      )
  }
  if (!okayToContinue) {
    return
  }
  const data = this.getFormData()
  const errors = this.validateBeforeSave(data, {})
  if (keys(errors).length === 0) {
    disablingDfd = new $.Deferred()
    saveDfd = this.saveFormData(data)
    // eslint-disable-next-line promise/catch-or-return
    saveDfd.then(this.onSaveSuccess.bind(this), this.onSaveFail.bind(this))
    saveDfd.fail(
      (function (_this) {
        return function () {
          disablingDfd.reject()
          if (_this.setFocusAfterError) {
            return _this.setFocusAfterError()
          }
        }
      })(this)
    )
    if (!this.dontRenableAfterSaveSuccess) {
      saveDfd.done(function () {
        return disablingDfd.resolve()
      })
    }
    this.$el.disableWhileLoading(disablingDfd, this.disableWhileLoadingOpts)
    if (rceInputs.length > 0) {
      rceInputs.forEach(
        (function (_this) {
          return function (rce) {
            return sendFunc($(rce), 'RCEClosed')
          }
        })(this)
      )
    }
    this.trigger('submit')
    return saveDfd
  } else {
    // focus on the first element with an error for accessibility
    dateOverrideErrors = map(
      $('[data-error-type]'),
      (function (_this) {
        return function (element) {
          return $(element).attr('data-error-type')
        }
      })(this)
    )
    assignmentFieldErrors = chain(keys(errors))
      .reject(function (err) {
        return includes(dateOverrideErrors, err)
      })
      .value()
    first_error = assignmentFieldErrors[0] || dateOverrideErrors[0]
    this.findField(first_error).focus()
    // short timeout to ensure alerts are properly read after focus change
    return window.setTimeout(
      (function (_this) {
        return function () {
          _this.showErrors(errors)
          return null
        }
      })(this),
      50
    )
  }
}

ValidatedFormView.prototype.cancel = function () {
  const rceInputs = this.$el.find('textarea[data-rich_text]').toArray()
  return rceInputs.forEach(
    (function (_this) {
      return function (rce) {
        return send($(rce), 'RCEClosed')
      }
    })(this)
  )
}

// Converts the form to an object. Override this if the form's input names
// don't match the model/API fields
ValidatedFormView.prototype.getFormData = function () {
  return sanitizeData(this.$el.toJSON())
}

// Saves data from the form using the model.
// Override to provide customized saving behavior.
ValidatedFormView.prototype.saveFormData = function (data) {
  if (data == null) {
    data = null
  }
  const model = this.model
  data || (data = this.getFormData())
  const saveOpts = this.saveOpts
  return model.save(data, saveOpts)
}

// Performs validation on the form, using the validateFormData method, and
// shows the errors using showErrors.
//
// Override validateFormData or showErrors to change their respective behaviors.
//
// @api public
// @returns true if there were no validation errors, otherwise false
ValidatedFormView.prototype.validate = function (opts) {
  if (opts == null) {
    opts = {}
  }
  opts || (opts = {})
  const data = opts.data || this.getFormData()
  const errors = this.validateFormData(data, {})
  this.hideErrors()
  this.showErrors(errors)
  return errors.length === 0
}

// Validates provided form data, returning any errors found.
// Override to provide customized validation behavior.
//
// @returns errors (see parseErrorResponse for the errors format)
ValidatedFormView.prototype.validateFormData = function (_data) {
  return {}
}

// Validates provided form data just before saving, returning any errors
// found. By default it delegates to @validateFormData to perform validation,
// but allows for alternative save-oriented validation to be performed.
// Override to provide customized pre-save validation behavior.
//
// @returns errors (see parseErrorResponse for the errors format)
ValidatedFormView.prototype.validateBeforeSave = function (data) {
  return this.validateFormData(data)
}

// Hides all errors previously shown in the UI.
// Override to match the way showErrors displays the errors.
ValidatedFormView.prototype.hideErrors = function () {
  return this.$el.hideErrors()
}

ValidatedFormView.prototype.onSaveSuccess = function (xhr) {
  // eslint-disable-next-line prefer-spread
  return this.trigger.apply(this, ['success', xhr].concat(slice.call(arguments)))
}

ValidatedFormView.prototype.onSaveFail = function (xhr) {
  let errors
  errors = this.parseErrorResponse(xhr)
  errors || (errors = {})
  this.showErrors(errors)
  // eslint-disable-next-line prefer-spread
  return this.trigger.apply(this, ['fail', errors].concat(slice.call(arguments)))
}

// Parses the response body into an error object `@showErrors` understands.
// Override for API end-points that don't follow convention, needs to return
// something that looks like this:
//
//   {
//     <field1>: [errors],
//     <field2>: [errors]
//   }
//
// For example:
//
//   {
//     first_name: [
//       {
//         type: 'required'
//         message: 'First name is required'
//       },
//       {
//         type: 'no_numbers',
//         message: "First name can't contain numbers"
//       }
//     ]
//   }
ValidatedFormView.prototype.parseErrorResponse = function (response) {
  if (response.status === 422) {
    return {
      authenticity_token: 'invalid',
    }
  } else {
    try {
      return JSON.parse(response.responseText).errors
    } catch (error1) {
      return {}
    }
  }
}

ValidatedFormView.prototype.translations = shimGetterShorthand(
  {},
  {
    required() {
      return I18n.t('required', 'Required')
    },
    blank() {
      return I18n.t('blank', 'Required')
    },
    unsaved() {
      return I18n.t('unsaved_changes', 'You have unsaved changes.')
    },
  }
)

// Errors are displayed relative to the field to which they belong. If
// the key of the error in the response doesn't match the name attribute
// of the form input element, configure a selector here.
//
// For example, given a form field like this:
//
//   <input name="user[first_name]">
//
// and an error response like this:
//
//   {errors: { first_name: {...} }}
//
// you would do this:
//
//   fieldSelectors:
//     first_name: '[name=user[first_name]]'
ValidatedFormView.prototype.fieldSelectors = null

ValidatedFormView.prototype.findField = function (field) {
  let $el, ref
  const selector =
    // eslint-disable-next-line no-void
    ((ref = this.fieldSelectors) != null ? ref[field] : void 0) || "[name='" + field + "']"
  $el = this.$(selector)
  if ($el.length === 0) {
    // 3rd fallback in case prior selectors find no elements
    $el = this.$("[data-error-type='" + field + "']")
  }
  if ($el.data('rich_text')) {
    $el = this.findSiblingTinymce($el)
  }
  if ($el.length > 1) {
    // e.g. hidden input + checkbox, show it by the checkbox
    $el = $el.not('[type=hidden]')
  }
  return $el
}

ValidatedFormView.prototype.castJSON = function (obj) {
  if (!isObject(obj)) {
    return obj
  }
  if (obj.toJSON != null) {
    return obj.toJSON()
  }
  const clone_ = clone(obj)
  forEach(
    clone_,
    (function (_this) {
      return function (val, key) {
        return (clone_[key] = _this.castJSON(val))
      }
    })(this)
  )
  return clone_
}

ValidatedFormView.prototype.original = null

ValidatedFormView.prototype.watchUnload = function () {
  this.original = this.castJSON(this.getFormData())
  this.unwatchUnload()
  return $(window).on('beforeunload', this.checkUnload)
}

ValidatedFormView.prototype.unwatchUnload = function () {
  return $(window).off('beforeunload', this.checkUnload)
}

ValidatedFormView.prototype.checkUnload = function () {
  const current = this.castJSON(this.getFormData())
  if (!isEqual(this.original, current)) {
    return this.translations.unsaved
  }
}

export default ValidatedFormView
