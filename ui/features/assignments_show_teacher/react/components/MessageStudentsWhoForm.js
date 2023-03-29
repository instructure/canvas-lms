/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func, number, string, arrayOf} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import {Select} from '@instructure/ui-select'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'

import {TeacherAssignmentShape} from '../assignmentData'
import {hasSubmission} from '@canvas/grading/messageStudentsWhoHelper'

const I18n = useI18nScope('assignments_2')

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */
export default class MessageStudentsWhoForm extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    pointsThreshold: number, // may also be null
    showPointsThreshold: bool,
    selectedFilter: string,
    subject: string,
    body: string,
    selectedStudents: arrayOf(string),
    onFilterChange: func,
    onPointsThresholdChange: func,
    onSubjectChange: func,
    onBodyChange: func,
    onSelectedStudentsChange: func,
  }

  static defaultProps = {
    pointsThreshold: null,
    showPointsThreshold: false,
    subject: '',
    body: '',
    onFilterChange: () => {},
    onPointsThresholdChange: () => {},
    onSubjectChange: () => {},
    onBodyChange: () => {},
    onSelectedStudentsChange: () => {},
  }

  getAllStudents() {
    return this.props.assignment.submissions.nodes.map(submission => submission.user)
  }

  handleFilterChange = (_event, selectedOption) => {
    this.props.onFilterChange(selectedOption.value)
  }

  handleStudentsChange = (_event, selection) => {
    this.props.onSelectedStudentsChange(selection.map(s => s.value))
  }

  handlePointsChangeString = (_event, stringValue) => {
    // special case: allow empty string
    if (stringValue.length === 0) {
      this.props.onPointsThresholdChange(null)
    } else {
      const newValue = Number.parseInt(stringValue, 10)
      if (!Number.isNaN(newValue)) {
        this.props.onPointsThresholdChange(Math.max(newValue, 0))
      } // else, they typed a non-number, so don't do anything
    }
  }

  handlePointsIncrement = () => {
    if (this.props.pointsThreshold === null) this.props.onPointsThresholdChange(1)
    else this.props.onPointsThresholdChange(this.props.pointsThreshold + 1)
  }

  handlePointsDecrement = () => {
    if (this.props.pointsThreshold === null) this.props.onPointsThresholdChange(0)
    else this.props.onPointsThresholdChange(Math.max(this.props.pointsThreshold - 1, 0))
  }

  handleChangeSubject = event => {
    this.props.onSubjectChange(event.target.value)
  }

  handleChangeBody = event => {
    this.props.onBodyChange(event.target.value)
  }

  renderScoreInput() {
    if (this.props.showPointsThreshold) {
      const points =
        this.props.pointsThreshold === null ? '' : this.props.pointsThreshold.toString()
      return (
        <NumberInput
          renderLabel={<ScreenReaderContent>{I18n.t('Points')}</ScreenReaderContent>}
          placeholder={I18n.t('Points')}
          value={points}
          onChange={this.handlePointsChangeString}
          onIncrement={this.handlePointsIncrement}
          onDecrement={this.handlePointsDecrement}
        />
      )
    } else return null
  }

  renderFilter() {
    const options = [
      {
        id: 'not-submitted',
        key: 'not-submitted',
        value: 'not-submitted',
        label: I18n.t("Haven't submitted yet"),
      },
      {
        id: 'not-graded',
        key: 'not-graded',
        value: 'not-graded',
        label: I18n.t("Haven't been graded"),
      },
      {id: 'less-than', key: 'less-than', value: 'less-than', label: I18n.t('Scored less than')},
      {id: 'more-than', key: 'more-than', value: 'more-than', label: I18n.t('Scored more than')},
    ]
    // not-submitted is only available if the assignment has an online submission
    if (!hasSubmission(this.props.assignment)) options.shift()
    return (
      <FormFieldGroup description="" layout="columns">
        <Select
          renderLabel={<ScreenReaderContent>{I18n.t('Filter Students')}</ScreenReaderContent>}
          selectedOption={this.props.selectedFilter}
          onChange={this.handleFilterChange}
          data-testid="filter-students"
        >
          {options.map(opt => (
            <Select.Option {...opt} />
          ))}
        </Select>
        {this.renderScoreInput()}
      </FormFieldGroup>
    )
  }

  render() {
    return (
      <FormFieldGroup description={I18n.t('Message students who')}>
        {this.renderFilter()}
        <Select
          renderLabel={I18n.t('To:')}
          multiple={true}
          selectedOption={this.props.selectedStudents}
          onChange={this.handleStudentsChange}
          data-testid="student-recipients"
          formatSelectedOption={tag => (
            <AccessibleContent alt={I18n.t('Remove %{studentName}', {studentName: tag.label})}>
              {tag.label}
            </AccessibleContent>
          )}
        >
          {this.getAllStudents().map(student => (
            <option key={student.lid} value={student.lid}>
              {student.name}
            </option>
          ))}
        </Select>

        <TextInput
          renderLabel={I18n.t('Subject:')}
          value={this.props.subject}
          onChange={this.handleChangeSubject}
          data-testid="subject-input"
        />
        <TextArea
          label={I18n.t('Body:')}
          value={this.props.body}
          onChange={this.handleChangeBody}
          data-testid="body-input"
        />
      </FormFieldGroup>
    )
  }
}
