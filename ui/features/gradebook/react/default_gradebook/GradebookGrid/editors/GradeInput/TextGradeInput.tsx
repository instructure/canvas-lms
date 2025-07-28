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
import {finalGradeOverrideUtils} from '@canvas/final-grade-override'

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

  // @ts-expect-error
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

  // @ts-expect-error
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
    // @ts-expect-error
    return this.state.gradeInfo
  }

  focus() {
    this.textInput?.focus()
    this.textInput?.setSelectionRange(0, this.textInput.value.length)
  }

  handleKeyDown(/* event */) {
    return undefined
  }

  // @ts-expect-error
  handleTextChange(event) {
    let {value} = event.target
    // @ts-expect-error
    if (this.props.gradeEntry.restrictToTwoDigitsAfterSeparator) {
      value = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator(value)
    }

    this.setState({
      // @ts-expect-error
      gradeInfo: this.props.gradeEntry.parseValue(value, true),
      inputValue: value,
    })
  }

  render() {
    return (
      <TextInput
        // @ts-expect-error
        disabled={this.props.disabled}
        inputRef={ref => {
          // @ts-expect-error
          this.textInput = ref
        }}
        // @ts-expect-error
        renderLabel={this.props.label}
        // @ts-expect-error
        messages={this.props.messages}
        onChange={this.handleTextChange}
        size="small"
        textAlign="center"
        // @ts-expect-error
        value={this.state.inputValue}
      />
    )
  }
}
