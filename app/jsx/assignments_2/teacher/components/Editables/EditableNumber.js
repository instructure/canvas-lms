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

import Text from '@instructure/ui-elements/lib/components/Text'
import NumberInput from '@instructure/ui-number-input/lib/components/NumberInput'
import InPlaceEdit from '@instructure/ui-editable/lib/components/InPlaceEdit'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import View from '@instructure/ui-layout/lib/components/View'
import {omitProps} from '@instructure/ui-utils/lib/react/passthroughProps'
import createChainedFunction from '@instructure/ui-utils/lib/createChainedFunction'

export default class EditableNumber extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired, // current mode
    label: string.isRequired, // label for the input element when in edit mode
    value: oneOfType([string, number]).isRequired, // the current text string
    onChange: func.isRequired, // when flips from edit to view, notify consumer of the new value
    onChangeMode: func.isRequired, // when mode changes
    onInputChange: func, // called as the user types. Usefull for checking validity
    placeholder: string, // the string to display when the text value is empty
    type: string, // the type attribute on the input element when in edit mode
    editButtonPlacement: oneOf(['start', 'end']), // is the edit button before or after the text?
    readOnly: bool,
    onInput: func, // called as the user types.
    isValid: func,
    inline: bool,
    required: bool,
    size: oneOf(['medium', 'large'])
  }

  static defaultProps = {
    type: 'text',
    placeholder: '',
    readOnly: false,
    required: false,
    size: 'medium',
    isValid: () => true,
    onInputChange: () => {}
  }

  constructor(props) {
    super(props)

    const strValue = `${props.value}`
    this.state = {
      value: strValue,
      initialValue: strValue
    }
  }

  // this.state.value holds the current value as the user is editing
  // once the mode flips from edit to view and the new value is
  // frozen, props.onChange tells our parent, who will re-render us
  // with this value in our props. This is where we reset our state
  // to reflect that new value
  static getDerivedStateFromProps(props, state) {
    const strValue = `${props.value}`
    if (state.initialValue !== strValue) {
      const newState = {...state}
      newState.value = strValue
      newState.initialValue = strValue
      return newState
    }
    return state
  }

  getSnapshotBeforeUpdate(prevProps, _prevState) {
    if (prevProps.mode === 'view' && this._textRef) {
      const fontSize = this.getFontSize(this._textRef)
      // we'll set the width of the <input> to the width of the text + 1 char
      return {width: this._textRef.offsetWidth + fontSize}
    }
    return null
  }

  componentDidUpdate(_prevProps, _prevState, snapshot) {
    if (this._inputRef) {
      if (snapshot) {
        this._inputRef.style.width = `${snapshot.width}px`
      } else {
        const fontSize = this.getFontSize(this._inputRef)
        let w = Math.min(this._inputRef.scrollWidth, this._inputRef.value.length * fontSize)
        if (w < 2 * fontSize) w = 2 * fontSize
        this._inputRef.style.width = `${w}px`
      }
    }
  }

  getFontSize(elem) {
    try {
      return parseInt(window.getComputedStyle(elem).getPropertyValue('font-size'), 10)
    } catch (_ignore) {
      return 16
    }
  }

  getInputRef = el => {
    this._textRef = null
    this._inputRef = el
  }

  getTextRef = el => {
    this._inputRref = null
    this._textRef = el
  }

  renderView = () => {
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    const color = this.state.value ? 'primary' : 'secondary'
    return (
      <Text
        {...p}
        color={color}
        weight={this.state.value ? 'normal' : 'light'}
        elementRef={this.getTextRef}
        size={this.props.size}
      >
        {getViewText(this.state.value || this.props.placeholder)}
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
    const p = omitProps(this.props, EditableNumber.propTypes, ['mode'])
    const len = this.state.value ? this.state.value.length + 1 : 3
    const width = `${Math.max(len, 3)}rem`
    return (
      <NumberInput
        {...p}
        value={this.state.value}
        placeholder={this.props.placeholder}
        showArrows={false}
        onChange={this.handleChange}
        onKeyDown={this.handleKey}
        label={<ScreenReaderContent>this.props.label</ScreenReaderContent>}
        onBlur={onBlur}
        inputRef={createChainedFunction(this.getInputRef, editorRef)}
        inline={this.props.inline}
        size={this.props.size}
        width={width}
        required={this.props.required}
      />
    )
  }

  renderEditButton = props => {
    if (!this.props.readOnly && this.props.isValid(this.state.value)) {
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  handleKey = event => {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.stopPropagation()
      this.handleModeChange('view')
    }
  }

  handleChange = (_event, newValue) => {
    this.setState(
      {
        value: newValue
      },
      () => {
        this.props.onInputChange(newValue)
      }
    )
  }

  handleModeChange = mode => {
    if (!this.props.readOnly) {
      if (mode === 'view' && !this.props.isValid(this.state.value)) {
        // can't leave edit mode with a bad value
        return
      }
      this.props.onChangeMode(mode)
    }
  }

  render() {
    return (
      <div>
        <InPlaceEdit
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEditor}
          renderEditButton={this.renderEditButton}
          value={this.state.value}
          onChange={this.props.onChange}
          editButtonPlacement={this.props.editButtonPlacement}
          showFocusRing={false}
        />
      </div>
    )
  }
}
