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
import {bool, string, func, element, oneOf, oneOfType, arrayOf, shape} from 'prop-types'
import {isEqual} from 'es-toolkit/compat'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import {InPlaceEdit} from '@instructure/ui-editable'
import {createChainedFunction} from '@instructure/ui-utils'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

const optShape = shape({
  label: string.isRequired,
  value: string.isRequired,
  icon: oneOfType([element, func]),
})

export default class SelectableText extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired, // current mode
    label: string.isRequired, // label for the input element when in edit mode
    value: oneOfType([optShape, arrayOf(optShape)]), // the selection. An option or array of options.
    onChange: func.isRequired, // when flips from edit to view, notify consumer of the new value
    renderView: func.isRequired, // render the view text. Necessary because the representation of what's
    // in the select and what's in the view may be very different
    onChangeMode: func, // called when the mode changes. if missing, it's assumed the mode is not permitted to cange
    onChangeSelection: func, // called when the user makes a selection in case the app needs to handle individual options uniquely
    editButtonPlacement: oneOf(['start', 'end']), // is the edit button before or after the text?
    readOnly: bool,
    multiple: bool,
    size: oneOf(['small', 'medium']),
    options: arrayOf(optShape).isRequired,
    loadingText: string,
  }

  static defaultProps = {
    readOnly: false,
    size: 'medium',
    multiple: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      value: props.value,
      initialValue: props.value,
    }

    // @ts-expect-error
    this._selectInputRef = null
  }

  // this.state.value holds the current value as the user is editing
  // once the mode flips from edit to view and the new value is
  // frozen, props.onChange tells our parent, who will re-render us
  // with this value in our props. This is where we reset our state
  // to reflect that new value
  // @ts-expect-error
  static getDerivedStateFromProps(props, state) {
    if (!isEqual(state.initialValue, props.value)) {
      const newState = {...state}
      newState.value = props.value
      newState.initialValue = props.value
      return newState
    }
    return null
  }

  // if we render the first time in edit mode, open the select
  componentDidMount() {
    // @ts-expect-error
    if (this._selectInputRef && this.props.mode === 'edit') {
      // @ts-expect-error
      this._selectInputRef.click()
    }
  }

  // when we flip from view to edit, automatically open the select
  // @ts-expect-error
  componentDidUpdate(prevProps) {
    // @ts-expect-error
    if (this._selectInputRef && this.props.mode === 'edit' && prevProps.mode === 'view') {
      // @ts-expect-error
      this._selectInputRef.click()
    }
  }

  // @ts-expect-error
  handleChange = (_event, selectedOption) => {
    this.setState({value: selectedOption})
    // @ts-expect-error
    if (this.props.onChangeSelection) {
      // @ts-expect-error
      this.props.onChangeSelection(selectedOption)
    }
  }

  // @ts-expect-error
  handleModeChange = mode => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      this.props.onChangeMode(mode)
    }
    // @ts-expect-error
    if (mode === 'view' && this._selectInputRef) {
      // @ts-expect-error
      this._selectInputRef.removeEventListener('keydown', this.handleKey)
      // @ts-expect-error
      this._selectInputRef = null
    }
    // @ts-expect-error
    this._select = null
  }

  handleOpenSelect = () => {
    // @ts-expect-error
    if (this.props.multiple) return
    requestAnimationFrame(() => {
      // @ts-expect-error
      if (this._selectInputRef) {
        // @ts-expect-error
        const w = this._selectInputRef.offsetWidth + 16
        // @ts-expect-error
        this._selectInputRef.style.width = `${w}px`
      }
    })
  }

  // @ts-expect-error
  getInputRef = el => {
    // @ts-expect-error
    this._selectInputRef = el
    if (el) {
      // @ts-expect-error
      this._selectInputRef.addEventListener('keydown', this.handleKey)
    }
  }

  // @ts-expect-error
  handleKey = event => {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.stopPropagation()
      this.handleModeChange('view')
      // @ts-expect-error
    } else if (this.props.mode === 'edit' && event.key === 'Escape') {
      // @ts-expect-error
      this.setState((state, _props) => ({value: state.initialValue}))
    }
  }

  renderView = () => {
    const sty = {marginBottom: '9px'} // so what's below doesn't move on mode change
    // @ts-expect-error
    return <div style={sty}>{this.props.renderView(this.state.value)}</div>
  }

  // @ts-expect-error
  renderEdit = ({onBlur, editorRef}) => {
    const sty = {margin: '-5px 0 0 -13px'} // so the text doesn't move when flipping to the Select
    return (
      <div style={sty}>
        <Select
          // @ts-expect-error
          label={<ScreenReaderContent>{this.props.label}</ScreenReaderContent>}
          // @ts-expect-error
          selectedOption={this.state.value}
          // @ts-expect-error
          onChange={this.handleChange}
          layout="inline"
          onBlur={onBlur}
          inputRef={createChainedFunction(this.getInputRef, editorRef)}
          // @ts-expect-error
          size={this.props.size}
          // @ts-expect-error
          multiple={this.props.multiple}
          onOpen={this.handleOpenSelect}
          // @ts-expect-error
          loadingText={this.props.loadingText}
        >
          {/* @ts-expect-error */}
          {this.renderOptions(this.props.options)}
        </Select>
      </div>
    )
  }

  // @ts-expect-error
  renderOptions(opts) {
    // @ts-expect-error
    return opts.map(o => (
      <option key={o.value} value={o.value}>
        {o.label}
      </option>
    ))
  }

  // Renders the edit button.
  // Leverage the default implemetation provided by InPlaceEdit
  // @ts-expect-error
  renderEditButton = props => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      props.label = this.props.label
      const sty = {marginBottom: '9px'} // so it has the same margin as the view
      return <div style={sty}>{InPlaceEdit.renderDefaultEditButton(props)}</div>
    }
    return null
  }

  render() {
    return (
      <div data-testid="SelectableText">
        <InPlaceEdit
          // @ts-expect-error
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          // @ts-expect-error
          onChange={this.props.onChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEdit}
          renderEditButton={this.renderEditButton}
          // @ts-expect-error
          value={this.state.value}
          showFocusRing={false}
          // @ts-expect-error
          editButtonPlacement={this.props.editButtonPlacement}
        />
      </div>
    )
  }
}
