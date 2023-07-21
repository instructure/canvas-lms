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
import isEqual from 'lodash/isEqual'

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

  constructor(props) {
    super(props)

    this.state = {
      value: props.value,
      initialValue: props.value,
    }

    this._selectInputRef = null
  }

  // this.state.value holds the current value as the user is editing
  // once the mode flips from edit to view and the new value is
  // frozen, props.onChange tells our parent, who will re-render us
  // with this value in our props. This is where we reset our state
  // to reflect that new value
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
    if (this._selectInputRef && this.props.mode === 'edit') {
      this._selectInputRef.click()
    }
  }

  // when we flip from view to edit, automatically open the select
  componentDidUpdate(prevProps) {
    if (this._selectInputRef && this.props.mode === 'edit' && prevProps.mode === 'view') {
      this._selectInputRef.click()
    }
  }

  handleChange = (_event, selectedOption) => {
    this.setState({value: selectedOption})
    if (this.props.onChangeSelection) {
      this.props.onChangeSelection(selectedOption)
    }
  }

  handleModeChange = mode => {
    if (!this.props.readOnly) {
      this.props.onChangeMode(mode)
    }
    if (mode === 'view' && this._selectInputRef) {
      this._selectInputRef.removeEventListener('keydown', this.handleKey)
      this._selectInputRef = null
    }
    this._select = null
  }

  handleOpenSelect = () => {
    if (this.props.multiple) return
    requestAnimationFrame(() => {
      if (this._selectInputRef) {
        const w = this._selectInputRef.offsetWidth + 16
        this._selectInputRef.style.width = `${w}px`
      }
    })
  }

  getInputRef = el => {
    this._selectInputRef = el
    if (el) {
      this._selectInputRef.addEventListener('keydown', this.handleKey)
    }
  }

  handleKey = event => {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.stopPropagation()
      this.handleModeChange('view')
    } else if (this.props.mode === 'edit' && event.key === 'Escape') {
      this.setState((state, _props) => ({value: state.initialValue}))
    }
  }

  renderView = () => {
    const sty = {marginBottom: '9px'} // so what's below doesn't move on mode change
    return <div style={sty}>{this.props.renderView(this.state.value)}</div>
  }

  renderEdit = ({onBlur, editorRef}) => {
    const sty = {margin: '-5px 0 0 -13px'} // so the text doesn't move when flipping to the Select
    return (
      <div style={sty}>
        <Select
          label={<ScreenReaderContent>{this.props.label}</ScreenReaderContent>}
          selectedOption={this.state.value}
          onChange={this.handleChange}
          layout="inline"
          onBlur={onBlur}
          inputRef={createChainedFunction(this.getInputRef, editorRef)}
          size={this.props.size}
          multiple={this.props.multiple}
          onOpen={this.handleOpenSelect}
          loadingText={this.props.loadingText}
        >
          {this.renderOptions(this.props.options)}
        </Select>
      </div>
    )
  }

  renderOptions(opts) {
    return opts.map(o => (
      <option key={o.value} value={o.value}>
        {o.label}
      </option>
    ))
  }

  // Renders the edit button.
  // Leverage the default implemetation provided by InPlaceEdit
  renderEditButton = props => {
    if (!this.props.readOnly) {
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
          mode={this.props.mode}
          onChangeMode={this.handleModeChange}
          onChange={this.props.onChange}
          renderViewer={this.renderView}
          renderEditor={this.renderEdit}
          renderEditButton={this.renderEditButton}
          value={this.state.value}
          showFocusRing={false}
          editButtonPlacement={this.props.editButtonPlacement}
        />
      </div>
    )
  }
}
