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
import {bool, string, func, oneOf} from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {InPlaceEdit} from '@instructure/ui-editable'
import {omitProps} from '@instructure/ui-react-utils'
import {createChainedFunction} from '@instructure/ui-utils'

export default class EditableHeading extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    label: string.isRequired, // label for the input element when in edit mode
    value: string.isRequired, // the current text string
    onChange: func.isRequired, // when flips from edit to view, notify consumer of the new value
    onChangeMode: func.isRequired, // when mode changes
    initialMode: oneOf(['view', 'edit']), // what mode should we start in. after that mode is handled internally
    placeholder: string, // the string to display when the text value is empty
    viewAs: string, // <Heading as={viewAs}> when in view mode
    editButtonPlacement: oneOf(['start', 'end']), // is the edit button before or after the text?
    level: oneOf(['h1', 'h2', 'h3', 'h4', 'h5']),
    readOnly: bool,
    required: bool,
  }

  static defaultProps = {
    viewAs: undefined,
    level: 'h2', // to match instui Heading default
    placeholder: '',
    readOnly: false,
    required: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      initialValue: props.value,
    }

    // @ts-expect-error
    this._inputRef = null
    // @ts-expect-error
    this._headingRef = null
    // @ts-expect-error
    this._hiddenTextRef = null
  }

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
      // if just flipped to edit, select all the text
      // @ts-expect-error
      if (prevProps.mode === 'view' && this.props.mode === 'edit') {
        // @ts-expect-error
        this._inputRef.setSelectionRange(0, Number.MAX_SAFE_INTEGER)
      }
    }
  }

  getFontSize() {
    let fontSize = 38
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
        fontSize = 38
      }
    }
    return fontSize
  }

  // get the space we need to reserve that's not actual text
  getPadding() {
    let padding = 6
    try {
      // @ts-expect-error
      if (this._inputRef) {
        // @ts-expect-error
        const cs = window.getComputedStyle(this._inputRef)
        // @ts-expect-error
        const lp = parseInt(cs.getProperty('padding-left'), 10)
        // @ts-expect-error
        const rp = parseInt(cs.getProperty('padding-right'), 10)
        // @ts-expect-error
        const lb = parseInt(cs.getProperty('border-left-width'), 10)
        // @ts-expect-error
        const rb = parseInt(cs.getProperty('border-right-width'), 10)
        padding = lp + rp + lb + rb
      }
    } catch (_ignore) {
      // ignore
    }
    return padding
  }

  getWidth() {
    const fsz = this.getFontSize()
    // @ts-expect-error
    let w = this.props.value.length * fsz
    // @ts-expect-error
    if (this._hiddenTextRef) {
      // @ts-expect-error
      w = Math.min(w, this._hiddenTextRef.offsetWidth + fsz / 2)
    }
    return `${w + this.getPadding()}px`
  }

  // @ts-expect-error
  getInputRef = el => {
    // @ts-expect-error
    this._headingRef = null
    // @ts-expect-error
    this._inputRef = el
    if (el) {
      // @ts-expect-error
      this._inputRef.style.minWidth = '2em'
    }
  }

  // @ts-expect-error
  getHeadingRef = el => {
    // @ts-expect-error
    this._inputRef = null
    // @ts-expect-error
    this._headingRef = el
  }

  // @ts-expect-error
  getHiddenTextRef = el => {
    // @ts-expect-error
    this._hiddenTextRef = el
  }

  renderView = () => {
    const p = omitProps(this.props, EditableHeading.propTypes, ['mode'])
    return (
      <div>
        <Heading
          {...p}
          // @ts-expect-error
          level={this.props.level}
          // @ts-expect-error
          color={this.props.value ? 'primary' : 'secondary'}
          // @ts-expect-error
          as={this.props.viewAs || this.props.level}
          elementRef={this.getHeadingRef}
        >
          {/* @ts-expect-error */}
          {this.props.value || this.props.placeholder}
        </Heading>
      </div>
    )
  }

  // @ts-expect-error
  renderEditor = ({onBlur, editorRef}) => {
    const p = omitProps(this.props, EditableHeading.propTypes, ['mode'])
    // move it a bit so it doesn't move on edit
    const sty = {
      margin: '-3px 0 0 -3px',
    }

    return (
      <div style={sty}>
        <Heading
          {...p}
          // @ts-expect-error
          level={this.props.level}
          as="input"
          // @ts-expect-error
          value={this.props.value}
          onChange={this.handleInputChange}
          onKeyDown={this.handleKey}
          onKeyUp={this.handleKey}
          // @ts-expect-error
          aria-label={this.props.label}
          onBlur={onBlur}
          elementRef={createChainedFunction(this.getInputRef, editorRef)}
        />
      </div>
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

  // don't have to check what mode is, because
  // this is the editor's key handler
  // @ts-expect-error
  handleKey = event => {
    if (event.key === 'Enter' && event.type === 'keydown') {
      event.preventDefault()
      event.stopPropagation()
      // @ts-expect-error
      if (!this.props.readOnly) {
        // @ts-expect-error
        this.props.onChangeMode('view')
      }
    } else if (event.key === 'Escape' && event.type === 'keyup') {
      // reset to initial value
      // @ts-expect-error
      this.props.onChange(this.state.initialValue)
    }
  }

  // @ts-expect-error
  handleInputChange = event => {
    // @ts-expect-error
    this.props.onChange(event.target.value)
  }

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
      <div data-testid="EditableHeading">
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
          value={this.props.value}
          onChange={this.handleChange}
          // @ts-expect-error
          editButtonPlacement={this.props.editButtonPlacement}
          showFocusRing={false}
        />
      </div>
    )
  }
}
