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

  // @ts-expect-error
  constructor(props) {
    super(props)

    const strValue = `${props.value}`
    this.state = {
      initialValue: strValue,
    }

    // @ts-expect-error
    this._inputRef = null
    // @ts-expect-error
    this._hiddenTextRef = null
  }

  // if a new value comes in while we're in view mode,
  // reset our initial value
  // @ts-expect-error
  static getDerivedStateFromProps(props, _state) {
    if (props.mode === 'view') {
      return {
        initialValue: props.value,
      }
    }
    return null
  }

  // @ts-expect-error
  componentDidUpdate(prevProps, _prevState, _snapshot) {
    // @ts-expect-error
    if (this._inputRef) {
      // @ts-expect-error
      this._inputRef.style.width = this.getWidth()
      // @ts-expect-error
      if (prevProps.mode === 'view' && this.props.mode === 'edit') {
        // @ts-expect-error
        this._inputRef.setSelectionRange(0, Number.MAX_SAFE_INTEGER)
      }
    }
  }

  getFontSize() {
    let fontSize = 22
    try {
      // @ts-expect-error
      if (this._inputRef) {
        fontSize = parseInt(
          window
            // @ts-expect-error
            .getComputedStyle(this._inputRef)
            .getPropertyValue('font-size'),
          10,
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
      // @ts-expect-error
      if (this._inputRef) {
        // @ts-expect-error
        const cs = window.getComputedStyle(this._inputRef)
        // @ts-expect-error
        const lp = parseInt(cs.getProperty('padding-left'), 10)
        // @ts-expect-error
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
    // @ts-expect-error
    let w = `${this.props.value}`.length * fsz
    // @ts-expect-error
    if (this._hiddenTextRef) {
      // @ts-expect-error
      w = Math.min(w, this._hiddenTextRef.offsetWidth + fsz)
    }
    return `${w + this.getPadding()}px`
  }

  // @ts-expect-error
  getInputRef = el => {
    // @ts-expect-error
    this._textRef = null
    // @ts-expect-error
    this._inputRef = el
    if (el) {
      // @ts-expect-error
      this._inputRef.style.minWidth = '2em'
    }
  }

  // @ts-expect-error
  getHiddenTextRef = el => {
    // @ts-expect-error
    this._hiddenTextRef = el
  }

  renderView = () => {
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    // @ts-expect-error
    const color = this.props.value ? 'primary' : 'secondary'
    return (
      <Text
        {...p}
        color={color}
        // @ts-expect-error
        weight={this.props.value ? 'normal' : 'light'}
        // @ts-expect-error
        size={this.props.size}
      >
        {/* @ts-expect-error */}
        {getViewText(this.props.value || this.props.placeholder)}
      </Text>
    )

    // @ts-expect-error
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

  // @ts-expect-error
  renderEditor = ({onBlur, editorRef}) => {
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    return (
      <NumberInput
        allowStringValue={true}
        {...p}
        // @ts-expect-error
        value={`${this.props.value}`}
        // @ts-expect-error
        placeholder={this.props.placeholder}
        showArrows={false}
        onChange={this.handleInputChange}
        onKeyDown={this.handleKey}
        onKeyUp={this.handleKey}
        renderLabel={<ScreenReaderContent>this.props.label</ScreenReaderContent>}
        onBlur={onBlur}
        inputRef={createChainedFunction(this.getInputRef, editorRef)}
        // @ts-expect-error
        display={this.props.inline ? 'inline-block' : 'block'}
        // @ts-expect-error
        size={this.props.size}
        // @ts-expect-error
        isRequired={this.props.required}
      />
    )
  }

  // @ts-expect-error
  renderEditButton = props => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  // Notes: if we handle Enter on keyup, we wind here when using enter
  // to click the edit button, and can't trigger edit via the kb
  // if we handle Escape via keydown, then Editable never calls onChangeMode
  // @ts-expect-error
  handleKey = event => {
    // don't have to check what mode is, because this is the editor's key handler
    if (event.key === 'Enter' && event.type === 'keydown') {
      event.preventDefault()
      event.stopPropagation()
      this.handleModeChange('view')
    } else if (event.key === 'Escape') {
      // reset to initial value
      // @ts-expect-error
      this.props.onChange(this.state.initialValue)
    }
  }

  // @ts-expect-error
  handleInputChange = (_event, newValue) => {
    // @ts-expect-error
    this.props.onInputChange(newValue)
  }

  // InPlaceEdit.onChange is fired when changing from edit to view
  // mode. Reset the initialValue now.
  // @ts-expect-error
  handleChange = newValue => {
    // @ts-expect-error
    this.props.onChange(newValue)
  }

  // @ts-expect-error
  handleModeChange = mode => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      if (this.props.mode === 'edit' && mode === 'view') {
        // @ts-expect-error
        this.props.onChange(this.props.value)
      }
      // @ts-expect-error
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
          {/* @ts-expect-error */}
          {this.props.value}
        </div>
        <InPlaceEdit
          // @ts-expect-error
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEditor}
          renderEditButton={this.renderEditButton}
          // @ts-expect-error
          value={this.state.value}
          onChange={this.handleChange}
          // @ts-expect-error
          editButtonPlacement={this.props.editButtonPlacement}
          showFocusRing={false}
        />
      </div>
    )
  }
}
