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
import _ from 'lodash'
import I18n from 'i18n!assignments_2'

import AccessibleContent from '@instructure/ui-a11y/lib/components/AccessibleContent'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import Select from '@instructure/ui-forms/lib/components/Select'

import {TeacherAssignmentShape} from '../assignmentData'

export default class MessageStudentsWhoForm extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape
  }

  constructor(...args) {
    super(...args)
    this.state = {
      selectedStudents: this.getAllStudents()
    }
  }

  getAllStudents() {
    return this.props.assignment.submissions.nodes.map(submission => submission.user)
  }

  handleFilterChange = (_event, selectedOption) => {
    if (selectedOption === 'not-submitted') this.handleNotSubmitted()
    else if (selectedOption === 'not-graded') this.handleNotGraded()
    else if (selectedOption === 'less-than') this.handleLessThan()
    else if (selectedOption === 'more-than') this.handleMoreThan()
    // eslint-disable-next-line no-console
    else console.error('MessageStudentsWhoForm error: unrecognized filter', selectedOption)
  }

  handleStudentsChange = (_event, selection) => {
    this.setState(() => ({
      selectedStudents: _.intersectionWith(
        this.getAllStudents(),
        selection,
        (student, selected) => student.lid === selected.value
      )
    }))
  }

  render() {
    return (
      <FormFieldGroup description={I18n.t('Message students who')}>
        <Select label="" onChange={this.handleFilterChange} inline>
          <option value="not-submitted">{I18n.t("Haven't submitted yet")}</option>
          <option value="not-graded">{I18n.t("Haven't been graded")}</option>
          <option value="less-than">{I18n.t('Scored less than')}</option>
          <option value="more-than">{I18n.t('Scored more than')}</option>
        </Select>

        <Select
          label={I18n.t('To:')}
          multiple
          selectedOption={this.state.selectedStudents.map(s => s.lid)}
          onChange={this.handleStudentsChange}
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

        <TextInput label={I18n.t('Subject:')} />
        <TextArea label={I18n.t('Body:')} />
      </FormFieldGroup>
    )
  }
}
