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
import I18n from 'i18n!theme_editor'
import customTypes from './PropTypes'

export default class ThemeEditorFileUpload extends Component {
  static propTypes = {
    label: PropTypes.string,
    accept: PropTypes.string,
    name: PropTypes.string,
    onChange: PropTypes.func.isRequired,
    currentValue: PropTypes.string,
    userInput: customTypes.userVariableInput,
    themeState: PropTypes.object,
    handleThemeStateChange: PropTypes.func
  }

  static defaultProps = {
    userInput: {},
    themeState: {},
    handleThemeStateChange() {}
  }

  state = {
    selectedFileName: ''
  }

  hasSomethingToReset = () => {
    return this.props.userInput.val || this.props.userInput.val === '' || this.props.currentValue
  }

  hasUserInput = () => {
    // null means the userInput has been reverted so ignore it
    return this.props.userInput.val !== null && this.props.userInput.val !== undefined
  }

  handleFileChanged = event => {
    var file = event.target.files[0]
    this.setState({selectedFileName: file.name})
    this.props.handleThemeStateChange(this.props.name, file, {customFileUpload: true})
    this.props.onChange(window.URL.createObjectURL(file))
  }

  handleResetClicked = () => {
    // if they hit the "Reset" button,
    // we want to also clear out the value of the <input type=file>
    // but we don't want to mess with its value otherwise
    this.fileInput.value = ''
    this.setState({selectedFileName: ''})
    this.props.handleThemeStateChange(this.props.name, null, {
      customFileUpload: true,
      resetValue: true,
      useDefault: !this.hasUserInput() && this.props.currentValue
    })
    this.props.onChange(!this.hasUserInput() ? '' : null)
  }

  displayValue() {
    if (!this.hasUserInput() && this.props.currentValue) {
      return this.props.currentValue
    } else if (this.props.userInput.val) {
      return this.state.selectedFileName
    } else {
      // no saved value and no unsaved value
      return ''
    }
  }

  resetButtonLabel() {
    if (this.props.userInput.val || this.props.userInput.val === '') {
      return (
        <span>
          <i className="icon-reset" aria-hidden="true" />
          <span className="screenreader-only">{I18n.t('Undo')}</span>
        </span>
      )
    } else if (this.props.currentValue) {
      return (
        <span>
          <i className="icon-x" aria-hidden="true" />
          <span className="screenreader-only">{I18n.t('Clear')}</span>
        </span>
      )
    } else {
      return <span className="screenreader-only">{I18n.t('Reset')}</span>
    }
  }

  viewFileLink() {
    return !this.hasUserInput() && this.props.currentValue ? (
      <a
        href={this.props.currentValue}
        target="_blank"
        className="ThemeEditorFileUpload__view-file"
      >
        {I18n.t('View File')}
      </a>
    ) : null
  }

  render() {
    return (
      <div className="ThemeEditorFileUpload">
        <div className="ThemeEditorFileUpload__label ic-Label">
          {this.props.label} {this.viewFileLink()}
        </div>
        <div className="ic-Input-group">
          <button
            disabled={!this.hasSomethingToReset()}
            type="button"
            className="ic-Input-group__add-on Button ThemeEditorFileUpload__reset-button"
            onClick={this.handleResetClicked}
          >
            {this.resetButtonLabel()}
          </button>
          <input
            type="hidden"
            name={!this.props.userInput.val && this.props.name}
            value={this.props.userInput.val === '' ? '' : this.props.currentValue}
          />
          <label className="ThemeEditorFileUpload__file-chooser">
            <span className="screenreader-only">{this.props.label}</span>
            <input
              type="file"
              name={this.props.userInput.val && this.props.name}
              accept={this.props.accept}
              onChange={this.handleFileChanged}
              ref={c => (this.fileInput = c)}
            />
            <div
              className="ThemeEditorFileUpload__fake-input uneditable-input ic-Input"
            >
              {this.displayValue()}
            </div>
            <div className="Button" aria-hidden="true">
              {I18n.t('Select')}
            </div>
          </label>
        </div>
      </div>
    )
  }
}
