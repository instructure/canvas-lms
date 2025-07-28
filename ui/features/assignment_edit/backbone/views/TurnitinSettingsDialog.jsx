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

import React from 'react'
import {createRoot} from 'react-dom/client'
import {extend} from '@canvas/backbone/utils'
import turnitinSettingsDialog from '../../jst/TurnitinSettingsDialog.handlebars'
import {extend as lodashExtend} from 'lodash'
import vericiteSettingsDialog from '../../jst/VeriCiteSettingsDialog.handlebars'
import {View} from '@canvas/backbone'
import htmlEscape from '@instructure/html-escape'
import '@canvas/util/jquery/fixDialogButtons'
import {useScope as createI18nScope} from '@canvas/i18n'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'

const I18n = createI18nScope('turnitinSettingsDialog')

const EXCLUDE_SMALL_MATCHES_OPTIONS = '.js-exclude-small-matches-options'
const EXCLUDE_SMALL_MATCHES = '#exclude_small_matches'
const EXCLUDE_SMALL_MATCHES_TYPE = '[name="exclude_small_matches_type"]'

const EXCLUDE_SMALL_MATCHES_WORDS = {
  TYPE: 'words',
  RADIO_SELECTOR: '[value="words"]',
  INPUT_SELECTOR: '[name="words"]',
  ERROR_CLASS: '.words_error_container'
}
const EXCLUDE_SMALL_MATCHES_PERCENT = {
  TYPE: 'percent',
  RADIO_SELECTOR: '[value="percent"]',
  INPUT_SELECTOR: '[name="percent"]',
  ERROR_CLASS: '.percent_error_container'
}

extend(TurnitinSettingsDialog, View)

TurnitinSettingsDialog.prototype.tagName = 'div'

function TurnitinSettingsDialog(model, type) {
  this.handleSubmit = this.handleSubmit.bind(this)
  this.getFormValues = this.getFormValues.bind(this)
  this.renderEl = this.renderEl.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.toggleExcludeOptions = this.toggleExcludeOptions.bind(this)
  TurnitinSettingsDialog.__super__.constructor.call(this, {
    model,
  })
  this.type = type
  this.errorRoots = {}
}

TurnitinSettingsDialog.prototype.events = (function () {
  const events = {}
  events.submit = 'handleSubmit'
  events['change ' + EXCLUDE_SMALL_MATCHES] = 'toggleExcludeOptions'
  events['change ' + EXCLUDE_SMALL_MATCHES_WORDS.RADIO_SELECTOR] = 'runValidation'
  events['input ' + EXCLUDE_SMALL_MATCHES_WORDS.INPUT_SELECTOR] = 'clearInputErrors'
  events['blur ' + EXCLUDE_SMALL_MATCHES_WORDS.INPUT_SELECTOR] = 'runValidation'
  events['change ' + EXCLUDE_SMALL_MATCHES_PERCENT.RADIO_SELECTOR] = 'runValidation'
  events['input ' + EXCLUDE_SMALL_MATCHES_PERCENT.INPUT_SELECTOR] = 'clearInputErrors'
  events['blur ' + EXCLUDE_SMALL_MATCHES_PERCENT.INPUT_SELECTOR] = 'runValidation'
  return events
})()

TurnitinSettingsDialog.prototype.els = (function () {
  const els = {}
  els['' + EXCLUDE_SMALL_MATCHES_OPTIONS] = '$excludeSmallMatchesOptions'
  els['' + EXCLUDE_SMALL_MATCHES] = '$excludeSmallMatches'
  els['' + EXCLUDE_SMALL_MATCHES_TYPE] = '$excludeSmallMatchesType'
  return els
})()

TurnitinSettingsDialog.prototype.getElement = function (selector) {
  // If the dialog has been closed and reopened, it will create a new dialog
  // so we need to query for all elements that match the selector and choose
  // the last one
  const allElements = document.querySelectorAll(selector)
  return allElements[allElements.length - 1]
}

TurnitinSettingsDialog.prototype.toggleExcludeOptions = function () {
  if (this.$excludeSmallMatches.prop('checked')) {
    // check if either radio button is checked. if not, check words by default
    const inputs = this.$excludeSmallMatchesType.toArray()
    if (inputs.every(input => !input.checked)) {
      this.getElement('input' + EXCLUDE_SMALL_MATCHES_WORDS.RADIO_SELECTOR).checked = true
    }
    return this.$excludeSmallMatchesOptions.show()
  } else {
    return this.$excludeSmallMatchesOptions.hide()
  }
}

TurnitinSettingsDialog.prototype.toJSON = function () {
  const json = TurnitinSettingsDialog.__super__.toJSON.apply(this, arguments)
  return lodashExtend(json, {
    wordsInput:
      '<input class="span1" id="exclude_small_matches_words_value" name="words" value="' +
      htmlEscape(json.words) +
      '" type="text"/>',
    percentInput:
      '<input class="span1" id="exclude_small_matches_percent_value" name="percent" value="' +
      htmlEscape(json.percent) +
      '" type="text"/>',
  })
}

TurnitinSettingsDialog.prototype.renderEl = function () {
  let html
  let title
  if (this.type === 'vericite') {
    html = vericiteSettingsDialog(this.toJSON())
  } else {
    html = turnitinSettingsDialog(this.toJSON())
    title = I18n.t('Advanced Turnitin Settings')
  }
  this.$el.html(html)
  return this.$el
    .dialog({
      title: title,
      width: 'auto',
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
}

TurnitinSettingsDialog.prototype.clearErrors = function (selector) {
  this.errorRoots[selector.TYPE]?.unmount()
  delete this.errorRoots[selector.TYPE]

  const inputContainer = this.getElement('input' + selector.INPUT_SELECTOR)
  inputContainer?.classList.remove('error-outline')
  inputContainer?.removeAttribute('aria-label')
}

TurnitinSettingsDialog.prototype.clearInputErrors = function (e) {
  if (e.target.name === EXCLUDE_SMALL_MATCHES_WORDS.TYPE) {
    this.clearErrors(EXCLUDE_SMALL_MATCHES_WORDS)
  } else {
    this.clearErrors(EXCLUDE_SMALL_MATCHES_PERCENT)
  }
}

TurnitinSettingsDialog.prototype.showErrorMessage = function (message, selectors, shouldFocus = false) {
  if (shouldFocus) {
    this.getElement(selectors.INPUT_SELECTOR)?.focus()
  }
  const inputContainer = this.getElement('input' + selectors.INPUT_SELECTOR)
  inputContainer?.classList.add('error-outline')
  inputContainer?.setAttribute('aria-label', message)
  const errorsContainer = this.getElement(selectors.ERROR_CLASS)
  if (errorsContainer) {
    const root = this.errorRoots[selectors.TYPE] ?? createRoot(errorsContainer)
    root.render(
       <FormattedErrorMessage
        message={message}
        margin="xx-small 0 small 0"
        iconMargin="0 xx-small xxx-small 0"
      />
    )

    Object.assign(this.errorRoots, {
      [selectors.TYPE]: root
    })
  }
}

TurnitinSettingsDialog.prototype.getErrorMessage = function (value, showEmptyError = false) {
  if (value) {
    const input = Number(value)
    if (!Number.isInteger(input)) {
      return I18n.t('Value must be a whole number')
    } else if (input <= 0) {
      return I18n.t('Value must be greater than 0')
    }
  } else if (showEmptyError) {
    return I18n.t('Value must not be empty')
  }
}

TurnitinSettingsDialog.prototype.validateInput = function (selectors) {
  const radioButtonChecked = this.getElement('input' + selectors.RADIO_SELECTOR)?.checked
  if (radioButtonChecked) {
    const inputContainer = this.getElement('input' + selectors.INPUT_SELECTOR)
    const message = this.getErrorMessage(inputContainer.value)
    if (message) {
      this.showErrorMessage(message, selectors)
    }
  }
}

TurnitinSettingsDialog.prototype.runValidation = function (e) {
  // validate onBlur or when the radio input gets checked
  if (e.type == 'focusout') {
    e.target.name === EXCLUDE_SMALL_MATCHES_WORDS.TYPE ? this.validateInput(EXCLUDE_SMALL_MATCHES_WORDS) : this.validateInput(EXCLUDE_SMALL_MATCHES_PERCENT)
  } else if (e.target.checked && e.target.value === EXCLUDE_SMALL_MATCHES_WORDS.TYPE) {
    this.clearErrors(EXCLUDE_SMALL_MATCHES_PERCENT)
    this.validateInput(EXCLUDE_SMALL_MATCHES_WORDS)
  } else if (e.target.checked && e.target.value === EXCLUDE_SMALL_MATCHES_PERCENT.TYPE) {
    this.clearErrors(EXCLUDE_SMALL_MATCHES_WORDS)
    this.validateInput(EXCLUDE_SMALL_MATCHES_PERCENT)
  }
}

TurnitinSettingsDialog.prototype.getFormValues = function () {
  const values = this.$el.find('form').toJSON()
  if (this.$excludeSmallMatches.prop('checked')) {
    if (values.exclude_small_matches_type === 'words') {
      values.exclude_small_matches_value = values.words
    } else {
      values.exclude_small_matches_value = values.percent
    }
  } else {
    values.exclude_small_matches_type = null
    values.exclude_small_matches_value = null
  }
  return values
}

TurnitinSettingsDialog.prototype.closeDialog = function (formValues) {
  this.$el.dialog('close')
  return this.trigger('settings:change', formValues)
}

TurnitinSettingsDialog.prototype.handleSubmit = function (ev) {
  ev.preventDefault()
  ev.stopPropagation()
  const formValues = this.getFormValues()
  // check if small matches is checked. if true, run validation
  if (this.$excludeSmallMatches.prop('checked')) {
    const error = this.getErrorMessage(formValues.exclude_small_matches_value, true)
    if (error) {
      this.showErrorMessage(error, formValues.exclude_small_matches_type === 'words' ? EXCLUDE_SMALL_MATCHES_WORDS : EXCLUDE_SMALL_MATCHES_PERCENT, true)
    } else {
      this.closeDialog(formValues)
    }
  } else {
    this.closeDialog(formValues)
  }
}

export default TurnitinSettingsDialog
