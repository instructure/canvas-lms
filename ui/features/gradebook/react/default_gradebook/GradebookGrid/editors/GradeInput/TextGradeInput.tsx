// @ts-nocheck
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

import React, {PureComponent} from 'react'
import {bool, element} from 'prop-types'
import {TextInput} from '@instructure/ui-text-input'

import {gradeEntry, gradeInfo, messages} from './PropTypes'

export default class TextGradeInput extends PureComponent {
  textInput?: HTMLInputElement

  static propTypes = {
    disabled: bool,
    gradeEntry: gradeEntry.isRequired,
    gradeInfo: gradeInfo.isRequired,
    label: element.isRequired,
    messages: messages.isRequired,
    pendingGradeInfo: gradeInfo,
  }

  static defaultProps = {
    disabled: false,
    pendingGradeInfo: null,
  }

  constructor(props) {
    super(props)

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleTextChange = this.handleTextChange.bind(this)

    const effectiveGradeInfo = props.pendingGradeInfo || props.gradeInfo

    this.state = {
      gradeInfo: effectiveGradeInfo,
      inputValue: props.gradeEntry.formatGradeInfoForInput(effectiveGradeInfo),
    }
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.textInput !== document.activeElement) {
      const nextInfo = nextProps.pendingGradeInfo || nextProps.gradeInfo

      this.setState({
        gradeInfo: nextInfo,
        inputValue: nextProps.gradeEntry.formatGradeInfoForInput(nextInfo),
      })
    }
  }

  get gradeInfo() {
    return this.state.gradeInfo
  }

  focus() {
    this.textInput?.focus()
    this.textInput?.setSelectionRange(0, this.textInput.value.length)
  }

  handleKeyDown(/* event */) {
    return undefined
  }

  handleTextChange(event) {
    this.setState({
      gradeInfo: this.props.gradeEntry.parseValue(event.target.value, true),
      inputValue: event.target.value,
    })
  }

  render() {
    return (
      <TextInput
        disabled={this.props.disabled}
        inputRef={ref => {
          this.textInput = ref
        }}
        renderLabel={this.props.label}
        messages={this.props.messages}
        onChange={this.handleTextChange}
        size="small"
        textAlign="center"
        value={this.state.inputValue}
      />
    )
  }
}
