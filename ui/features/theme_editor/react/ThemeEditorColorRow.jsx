/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import rgb2hex from '@canvas/util/rgb2hex'
import classnames from 'classnames'

const I18n = useI18nScope('theme_editor')

export default class ThemeEditorColorRow extends Component {
  static propTypes = {
    varDef: customTypes.color,
    onChange: PropTypes.func.isRequired,
    userInput: customTypes.userVariableInput,
    placeholder: PropTypes.string.isRequired,
    themeState: PropTypes.object,
    handleThemeStateChange: PropTypes.func,
  }

  static defaultProps = {
    userInput: {},
    themeState: {},
    handleThemeStateChange() {},
  }

  state = {}

  showWarning = () => this.props.userInput.invalid && this.inputNotFocused()

  warningLabel = () => {
    if (this.showWarning()) {
      return (
        <span role="alert">
          {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
          <div className="ic-Form-message ic-Form-message--error" tabIndex="0">
            <div className="ic-Form-message__Layout">
              <i className="icon-warning" role="presentation" />
              {I18n.t("'%{chosenColor}' is not a valid color.", {
                chosenColor: this.props.userInput.val,
              })}
            </div>
          </div>
        </span>
      )
    } else {
      // must return empty alert span so screenreaders
      // read the error when it is inserted
      return <span role="alert" />
    }
  }

  changedColor(value) {
    // fail fast for no value
    if (!value) return null

    // set and read color values from a dom node to get only valid values
    const tempNode = document.createElement('span')
    tempNode.style.backgroundColor = value
    const color = tempNode.style.backgroundColor

    // reject invalid values
    if (!color) return null

    // FF returns 'transparent' for invalid colors, but we allow intentionally setting a value to 'transparent'
    if (color === 'transparent' && value !== 'transparent') return null

    return color
  }

  hexVal = colorString => {
    const rgbVal = this.changedColor(colorString)
    // rgb2hex will fail if rgbVal is null or undefined
    return rgbVal ? rgb2hex(rgbVal) || rgbVal : ''
  }

  invalidHexString(colorString) {
    return colorString.match(/#/) ? !colorString.match(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/) : false
  }

  inputChange = value => {
    const invalidColor = !!value && (!this.changedColor(value) || this.invalidHexString(value))
    this.props.onChange(value, invalidColor)
    if (!invalidColor) {
      this.props.handleThemeStateChange(this.props.varDef.variable_name, value)
    }
  }

  inputNotFocused = () => this.textInput && this.textInput !== document.activeElement

  updateIfMounted = () => {
    this.forceUpdate()
  }

  textColorInput = () => (
    <span>
      <input
        ref={c => (this.textInput = c)}
        type="text"
        id={`brand_config[variables][${this.props.varDef.variable_name}]`}
        className={classnames({
          'Theme__editor-color-block_input-text': true,
          'Theme__editor-color-block_input': true,
          'Theme__editor-color-block_input--has-error': this.props.userInput.invalid,
        })}
        placeholder={this.props.placeholder}
        value={this.props.themeState[this.props.varDef.variable_name]}
        aria-invalid={this.showWarning()}
        onChange={event => this.inputChange(event.target.value)}
        onBlur={this.updateIfMounted}
      />
    </span>
  )

  render() {
    const colorInputValue = this.props.placeholder !== 'none' ? this.props.placeholder : null
    return (
      <section className="Theme__editor-accordion_element Theme__editor-color ic-Form-control">
        <div className="Theme__editor-form--color">
          <label
            htmlFor={`brand_config[variables][${this.props.varDef.variable_name}]`}
            className="Theme__editor-color_title"
          >
            {this.props.varDef.human_name}
          </label>
          <div className="Theme__editor-color-block">
            {this.textColorInput()}
            {this.warningLabel()}
            {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
            <label
              className="Theme__editor-color-label Theme__editor-color-block_label-sample"
              style={{backgroundColor: this.props.placeholder}}
              /* this <label> and <input type=color> are here so if you click the 'sample',
              it will pop up a color picker on browsers that support it */
            >
              <input
                className="Theme__editor-color-block_input-sample Theme__editor-color-block_input"
                type="color"
                value={colorInputValue}
                // eslint-disable-next-line jsx-a11y/no-interactive-element-to-noninteractive-role
                role="presentation"
                onChange={event => this.inputChange(event.target.value)}
              />
            </label>
          </div>
        </div>
      </section>
    )
  }
}
