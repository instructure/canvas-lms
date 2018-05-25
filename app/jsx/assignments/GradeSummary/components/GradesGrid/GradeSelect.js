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

export default class GradeSelect extends Component {
  static propTypes = {
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    onClose: func,
    onOpen: func,
    onSelect: func,
    selectProvisionalGradeStatus: oneOf([FAILURE, STARTED, SUCCESS]),
    studentName: string.isRequired
  }

  static defaultProps = {
    onClose() {},
    onOpen() {},
    onSelect() {},
    selectProvisionalGradeStatus: null
  }

  constructor(props) {
    super(props)

    this.handleSelect = this.handleSelect.bind(this)
  }

  shouldComponentUpdate(nextProps) {
    return Object.keys(nextProps).some(key => this.props[key] !== nextProps[key])
  }

  handleSelect(_event, option) {
    const gradeInfo = this.props.grades[option.value]
    if (!gradeInfo.selected && this.props.onSelect) {
      this.props.onSelect(gradeInfo)
    }
  }

  render() {
    const {graders, grades} = this.props
    const gradeOptions = []

    let selectedOption
    for (let i = 0; i < graders.length; i++) {
      const grader = graders[i]
      const gradeInfo = grades[grader.graderId]

      if (gradeInfo != null) {
        const option = {
          label: `${I18n.n(gradeInfo.score)} (${grader.graderName})`,
          value: gradeInfo.graderId
        }
        gradeOptions.push(option)

        if (gradeInfo.selected) {
          selectedOption = option
        }
      }
    }

    if (!selectedOption) {
      gradeOptions.unshift({label: '–', value: 'no-selection'})
      selectedOption = 'no-selection'
    }

    return (
      <Select
        aria-readonly={!this.props.onSelect || this.props.selectProvisionalGradeStatus === STARTED}
        key={
          /*
           * TODO: This forces a unique instance per-student, which hurts
           * performance.  Remove this key entirely once the commit from
           * INSTUI-1199 has been published to npm and pulled into Canvas.
           */
          this.props.studentName
        }
        label={
          <ScreenReaderContent>
            {I18n.t('Grade for %{studentName}', {studentName: this.props.studentName})}
          </ScreenReaderContent>
        }
        onChange={this.handleSelect}
        onClose={this.props.onClose}
        onOpen={this.props.onOpen}
        selectedOption={selectedOption}
      >
        {gradeOptions.map(gradeOption => (
          <option key={gradeOption.value} value={gradeOption.value}>
            {gradeOption.label}
          </option>
        ))}
      </Select>
    )
  }
}
