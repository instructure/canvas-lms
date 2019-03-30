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

import Heading from '@instructure/ui-elements/lib/components/Heading'
import InPlaceEdit from '@instructure/ui-editable/lib/components/InPlaceEdit'
import Text from '@instructure/ui-elements/lib/components/Text'
import {omitProps} from '@instructure/ui-utils/lib/react/passthroughProps'
import createChainedFunction from '@instructure/ui-utils/lib/createChainedFunction'

export default class EditableHeading extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    label: string.isRequired, // label for the input element when in edit moded
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
    requiredMessage: string
  }

  static defaultProps = {
    viewAs: undefined,
    level: 'h2', // to match instui Heading default
    placeholder: '',
    readOnly: false,
    required: false
  }

  constructor(props) {
    super(props)

    this.state = {
      value: props.value,
      initialValue: props.value
    }
  }

  // this.state.value holds the current value as the user is editing
  // once the mode flips from edit to view and the new value is
  // frozen, props.onChange tells our parent, who will re-render us
  // with this value in our props. This is where we reset our state
  // to reflect that new value
  static getDerivedStateFromProps(props, state) {
    if (state.initialValue !== props.value) {
      const newState = {...state}
      newState.value = props.value
      newState.initialValue = props.value
      return newState
    }
    return null
  }

  getSnapshotBeforeUpdate(prevProps, _prevState) {
    if (prevProps.mode === 'view' && this._headingRef) {
      const fontSize = this.getFontSize(this._headingRef)
      // we'll set the width of the <input> to the width of the text + 1 char
      return {width: this._headingRef.clientWidth + fontSize}
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
    this._headingRef = null
    this._inputRef = el
  }

  getHeadingRef = el => {
    this._inputRef = null
    this._headingRef = el
  }

  renderView = () => {
    const msg =
      this.props.required && !this.state.value ? (
        <div>
          <Text color="error">{this.props.requiredMessage}</Text>
        </div>
      ) : null
    const p = omitProps(this.props, EditableHeading.propTypes, ['mode'])
    return (
      <div>
        <Heading
          {...p}
          level={this.props.level}
          color={this.state.value ? 'primary' : 'secondary'}
          as={this.props.viewAs || this.props.level}
          elementRef={this.getHeadingRef}
        >
          {this.state.value || this.props.placeholder}
        </Heading>
        {msg}
      </div>
    )
  }

  renderEditor = ({onBlur, editorRef}) => {
    const p = omitProps(this.props, EditableHeading.propTypes, ['mode'])
    // move it a bit so it doesn't move on edit
    const sty = {
      margin: '-3px 0 0 -3px'
    }

    return (
      <div style={sty}>
        <Heading
          {...p}
          level={this.props.level}
          as="input"
          value={this.state.value}
          onChange={this.handleChange}
          onKeyDown={this.handleKey}
          aria-label={this.props.label}
          onBlur={onBlur}
          elementRef={createChainedFunction(this.getInputRef, editorRef)}
        />
      </div>
    )
  }

  renderEditButton = props => {
    if (!this.props.readOnly) {
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  handleKey = event => {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.stopPropagation()
      if (!this.props.readOnly) {
        this.props.onChangeMode('view')
      }
    }
  }

  handleChange = event => {
    this.setState({value: event.target.value})
  }

  handleModeChange = mode => {
    if (!this.props.readOnly) {
      this.props.onChangeMode(mode)
    }
  }

  render() {
    return (
      <div className="EditableHeading">
        <InPlaceEdit
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEditor}
          renderEditButton={this.renderEditButton}
          value={this.state.value}
          onChange={this.props.onChange}
          editButtonPlacement={this.props.editButtonPlacement}
        />
      </div>
    )
  }
}
