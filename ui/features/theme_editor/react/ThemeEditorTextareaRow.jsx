/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {Component} from 'react'
import PropTypes from 'prop-types'
import customTypes from '@canvas/theme-editor/react/PropTypes'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('theme_editor')
const TEXTAREA_CHARACTER_LIMIT = 500
const TEXTAREA_WARNING_BUFFER = 50
const TEXTAREA_WARNING_THRESHOLD = TEXTAREA_CHARACTER_LIMIT - TEXTAREA_WARNING_BUFFER

export default class ThemeEditorTextareaRow extends Component {
  static propTypes = {
    currentValue: PropTypes.string,
    handleThemeStateChange: PropTypes.func,
    onChange: PropTypes.func.isRequired,
    placeholder: PropTypes.string,
    themeState: PropTypes.object,
    userInput: customTypes.userVariableInput,
    varDef: customTypes.textarea,
  }

  static defaultProps = {
    handleThemeStateChange() {},
    themeState: {},
  }

  inputChange = value => {
    this.props.onChange(value)
    this.props.handleThemeStateChange(this.props.varDef.variable_name, value)
  }

  render() {
    const {varDef, themeState, placeholder, userInput, currentValue} = this.props
    const textareaId = `brand_config[variables][${varDef.variable_name}]`
    let textareaValue = ''

    if (userInput && userInput.val !== undefined) {
      textareaValue = userInput.val
    } else if (currentValue) {
      textareaValue = currentValue
    } else if (themeState && themeState[varDef.variable_name]) {
      textareaValue = themeState[varDef.variable_name]
    }

    const charCount = textareaValue.length
    let charCountClass = 'Theme__editor-textarea_character-count'
    let statusText = ''

    if (charCount >= TEXTAREA_CHARACTER_LIMIT) {
      charCountClass += ' Theme__editor-textarea_character-count--limit'
      statusText = `${I18n.t('character limit reached')} `
    } else if (charCount >= TEXTAREA_WARNING_THRESHOLD) {
      charCountClass += ' Theme__editor-textarea_character-count--warning'
    }

    return (
      <section className="Theme__editor-accordion_element Theme__editor-textarea">
        <div className="Theme__editor-form--textarea">
          <div className="Theme__editor-textarea_header">
            <label className="Theme__editor-textarea_title" htmlFor={textareaId}>
              {varDef.human_name}
            </label>

            <span className="Theme__editor-textarea_restrictions" id={`${textareaId}-helper`}>
              {varDef.helper_text}
            </span>
          </div>

          <textarea
            aria-describedby={`${textareaId}-helper ${textareaId}-count`}
            className="Theme__editor-textarea_input"
            data-testid="theme-editor-textarea-input"
            id={textareaId}
            maxLength={TEXTAREA_CHARACTER_LIMIT}
            name={textareaId}
            onChange={e => this.inputChange(e.target.value)}
            placeholder={placeholder}
            rows={4}
            value={textareaValue}
          />

          <div
            aria-live="polite"
            className={charCountClass}
            data-testid="theme-editor-character-count"
            id={`${textareaId}-count`}
          >
            {statusText}
            {charCount}/{TEXTAREA_CHARACTER_LIMIT}
          </div>
        </div>
      </section>
    )
  }
}
