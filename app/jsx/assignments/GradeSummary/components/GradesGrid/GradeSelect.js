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

import React, {Component} from 'react'
import {arrayOf, func, oneOf, shape, string} from 'prop-types'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Select from '@instructure/ui-forms/lib/components/Select'
import I18n from 'i18n!assignment_grade_summary'

import {FAILURE, STARTED, SUCCESS} from '../../grades/GradeActions'

const NO_SELECTION = 'no-selection'

function optionsForGraders(graders, grades) {
  const options = []
  for (let i = 0; i < graders.length; i++) {
    const grader = graders[i]
    const gradeInfo = grades[grader.graderId]
    if (gradeInfo) {
      options.push({
        gradeInfo,
        label: `${I18n.n(gradeInfo.score)} (${grader.graderName})`,
        value: gradeInfo.graderId
      })
    }
  }
  return options
}

export default class GradeSelect extends Component {
  static propTypes = {
    /* eslint-disable-next-line react/no-unused-prop-types */
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    /* eslint-disable-next-line react/no-unused-prop-types */
    grades: shape({}).isRequired,
    onClose: func,
    onOpen: func,
    onPositioned: func,
    onSelect: func,
    selectProvisionalGradeStatus: oneOf([FAILURE, STARTED, SUCCESS]),
    studentName: string.isRequired
  }

  static defaultProps = {
    onClose() {},
    onOpen() {},
    onPositioned() {},
    onSelect() {},
    selectProvisionalGradeStatus: null
  }

  constructor(props) {
    super(props)

    this.bindMenu = ref => {
      if (ref) {
        this.$input = ref
        const menuId = ref.getAttribute('aria-controls')
        this.$menu = document.getElementById(menuId)
      } else {
        this.$menu = null
      }
    }
    this.bindSelect = ref => {
      this.select = ref
    }

    this.handleChange = this.handleChange.bind(this)
    this.handleClose = this.handleClose.bind(this)

    this.state = this.constructor.getDerivedStateFromProps(props)
  }

  static getDerivedStateFromProps(props) {
    const graderOptions = optionsForGraders(props.graders, props.grades)
    const options = [...graderOptions]
    let selectedOption = options.find(option => option.gradeInfo.selected)
    if (!selectedOption) {
      selectedOption = {gradeInfo: {}, label: '–', value: NO_SELECTION}
      options.unshift(selectedOption)
    }

    return {
      enteredOption: selectedOption,
      graderOptions,
      options,
      selectedOption
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState(this.constructor.getDerivedStateFromProps(nextProps))
  }

  shouldComponentUpdate(nextProps, nextState) {
    return (
      Object.keys(nextProps).some(key => this.props[key] !== nextProps[key]) ||
      Object.keys(nextState).some(key => this.state[key] !== nextState[key])
    )
  }

  handleChange(_event, selectedOption) {
    if (this.props.onSelect == null || selectedOption.value === NO_SELECTION) {
      return
    }

    const optionMatch = this.state.options.find(option => option.value === selectedOption.value)
    if (!optionMatch.gradeInfo.selected) {
      this.props.onSelect(optionMatch.gradeInfo)
    }
  }

  handleClose() {
    if (this.$input === document.activeElement || this.$menu.contains(document.activeElement)) {
      this.select.focus()
    }

    if (this.props.onClose) {
      this.props.onClose()
    }
  }

  render() {
    return (
      <Select
        aria-readonly={!this.props.onSelect || this.props.selectProvisionalGradeStatus === STARTED}
        filter={options => options}
        inputRef={this.bindMenu}
        label={
          <ScreenReaderContent>
            {I18n.t('Grade for %{studentName}', {studentName: this.props.studentName})}
          </ScreenReaderContent>
        }
        onChange={this.handleChange}
        onClose={this.handleClose}
        onOpen={this.props.onOpen}
        onPositioned={this.props.onPositioned}
        ref={this.bindSelect}
        selectedOption={this.state.selectedOption}
      >
        {this.state.options.map(gradeOption => (
          <option key={gradeOption.value} value={gradeOption.value}>
            {gradeOption.label}
          </option>
        ))}
      </Select>
    )
  }
}
