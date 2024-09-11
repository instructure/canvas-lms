/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, string, func, number, oneOf, oneOfType} from 'prop-types'

import {Text} from '@instructure/ui-text'
import {NumberInput} from '@instructure/ui-number-input'
import {InPlaceEdit} from '@instructure/ui-editable'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {omitProps} from '@instructure/ui-react-utils'
import {createChainedFunction} from '@instructure/ui-utils'

export default class EditableNumber extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired, // current mode
    label: string.isRequired, // label for the input element when in edit mode
    value: oneOfType([string, number]).isRequired, // the current text string
    onChange: func.isRequired, // when flips from edit to view, notify consumer of the new value
    onChangeMode: func.isRequired, // when mode changes
    onInputChange: func, // called as the user types. Usefull for checking validity
    placeholder: string, // the sting to display when the text value is empty
    type: string, // the type attribute on the input element when in edit mode
    editButtonPlacement: oneOf(['start', 'end']), // is the edit button before or after the text?
    readOnly: bool,
    onInput: func, // called as the user types.
    inline: bool,
    required: bool,
    size: oneOf(['medium', 'large']),
  }

  static defaultProps = {
    type: 'text',
    placeholder: '',
    readOnly: false,
    required: false,
    size: 'medium',
    onInputChange: () => {},
  }

  constructor(props) {
    super(props)

    const strValue = `${props.value}`
    this.state = {
      initialValue: strValue,
    }

    this._inputRef = null
    this._hiddenTextRef = null
  }

  // if a new value comes in while we're in view mode,
  // reset our initial value
  static getDerivedStateFromProps(props, _state) {
    if (props.mode === 'view') {
      return {
        initialValue: props.value,
      }
    }
    return null
  }

  componentDidUpdate(prevProps, _prevState, _snapshot) {
    if (this._inputRef) {
      this._inputRef.style.width = this.getWidth()
      if (prevProps.mode === 'view' && this.props.mode === 'edit') {
        this._inputRef.setSelectionRange(0, Number.MAX_SAFE_INTEGER)
      }
    }
  }

  getFontSize() {
    let fontSize = 22
    try {
      if (this._inputRef) {
        fontSize = parseInt(
          window.getComputedStyle(this._inputRef).getPropertyValue('font-size'),
          10
        )
      }
    } catch (_ignore) {
      // ignore
    } finally {
      if (Number.isNaN(fontSize)) {
        fontSize = 22
      }
    }
    return fontSize
  }

  getPadding() {
    let padding = 23
    try {
      if (this._inputRef) {
        const cs = window.getComputedStyle(this._inputRef)
        const lp = parseInt(cs.getProperty('padding-left'), 10)
        const rp = parseInt(cs.getProperty('padding-right'), 10)
        padding = lp + rp
      }
    } catch (_ignore) {
      // ignore
    }
    return padding
  }

  getWidth() {
    const fsz = this.getFontSize()
    let w = `${this.props.value}`.length * fsz
    if (this._hiddenTextRef) {
      w = Math.min(w, this._hiddenTextRef.offsetWidth + fsz)
    }
    return `${w + this.getPadding()}px`
  }

  getInputRef = el => {
    this._textRef = null
    this._inputRef = el
    if (el) {
      this._inputRef.style.minWidth = '2em'
    }
  }

  getHiddenTextRef = el => {
    this._hiddenTextRef = el
  }

  renderView = () => {
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    const color = this.props.value ? 'primary' : 'secondary'
    return (
      <Text
        {...p}
        color={color}
        weight={this.props.value ? 'normal' : 'light'}
        size={this.props.size}
      >
        {getViewText(this.props.value || this.props.placeholder)}
      </Text>
    )

    function getViewText(text) {
      if (text) return text

      const borderWidth = 'small'
      const minWidth = '1.5rem'
      const minHeight = minWidth
      return (
        <View
          display="inline-block"
          borderWidth={borderWidth}
          minWidth={minWidth}
          minHeight={minHeight}
        />
      )
    }
  }

  renderEditor = ({onBlur, editorRef}) => {
    // eslint-disable-next-line react/forbid-foreign-prop-types
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    return (
      <NumberInput
        {...p}
        value={`${this.props.value}`}
        placeholder={this.props.placeholder}
        showArrows={false}
        onChange={this.handleInputChange}
        onKeyDown={this.handleKey}
        onKeyUp={this.handleKey}
        renderLabel={<ScreenReaderContent>this.props.label</ScreenReaderContent>}
        onBlur={onBlur}
        inputRef={createChainedFunction(this.getInputRef, editorRef)}
        display={this.props.inline ? 'inline-block' : 'block'}
        size={this.props.size}
        isRequired={this.props.required}
      />
    )
  }

  renderEditButton = props => {
    if (!this.props.readOnly) {
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  // Notes: if we handle Enter on keyup, we wind here when using enter
  // to click the edit button, and can't trigger edit via the kb
  // if we handle Escape via keydown, then Editable never calls onChangeMode
  handleKey = event => {
    // don't have to check what mode is, because this is the editor's key handler
    if (event.key === 'Enter' && event.type === 'keydown') {
      event.preventDefault()
      event.stopPropagation()
      this.handleModeChange('view')
    } else if (event.key === 'Escape') {
      // reset to initial value
      this.props.onChange(this.state.initialValue)
    }
  }

  handleInputChange = (_event, newValue) => {
    this.props.onInputChange(newValue)
  }

  // InPlaceEdit.onChange is fired when changing from edit to view
  // mode. Reset the initialValue now.
  handleChange = newValue => {
    this.props.onChange(newValue)
  }

  handleModeChange = mode => {
    if (!this.props.readOnly) {
      if (this.props.mode === 'edit' && mode === 'view') {
        this.props.onChange(this.props.value)
      }
      this.props.onChangeMode(mode)
    }
  }

  render() {
    return (
      <div>
        <div
          style={{
            position: 'absolute',
            display: 'inline-block',
            top: '-1000px',
            fontSize: this.getFontSize(),
          }}
          ref={this.getHiddenTextRef}
        >
          {this.props.value}
        </div>
        <InPlaceEdit
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEditor}
          renderEditButton={this.renderEditButton}
          value={this.state.value}
          onChange={this.handleChange}
          editButtonPlacement={this.props.editButtonPlacement}
          showFocusRing={false}
        />
      </div>
    )
  }
}
