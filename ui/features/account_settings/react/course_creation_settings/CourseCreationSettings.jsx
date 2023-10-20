/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'

const I18n = useI18nScope('course_creation_settings')

const locationRadioInputs = [
  {
    key: 'anywhere',
    value: '1',
    label: I18n.t('Allow creation anywhere the user has active enrollments'),
  },
  {
    key: 'manuallyCreatedCourses',
    value: '0',
    label: I18n.t('Allow creation only in the Manually-Created Courses sub-account'),
  },
]

const formatInputName = name => `account[settings][${name}]`

const CourseCreationSettings = ({currentValues}) => {
  const [isTeachersChecked, setTeachersChecked] = useState(
    currentValues.teachers_can_create_courses
  )
  const [isStudentsChecked, setStudentsChecked] = useState(
    currentValues.students_can_create_courses
  )
  const [isNoEnrollmentsChecked, setNoEnrollmentsChecked] = useState(
    currentValues.no_enrollments_can_create_courses
  )

  return (
    <View as="div" data-testid="course-creation-settings">
      <View as="div" margin="0 0 small">
        <Text weight="bold">{I18n.t('Account Administrators can always create courses')}</Text>
      </View>

      <FormFieldGroup
        description={
          <ScreenReaderContent>
            {I18n.t('Select users who can create new courses')}
          </ScreenReaderContent>
        }
        layout="stacked"
        rowSpacing="small"
      >
        <input type="hidden" name={formatInputName('teachers_can_create_courses')} value={0} />
        <Checkbox
          label={I18n.t('Teachers')}
          name={formatInputName('teachers_can_create_courses')}
          value={1}
          checked={isTeachersChecked}
          onChange={e => setTeachersChecked(e.target.checked)}
        />
        {isTeachersChecked && (
          <View as="div" padding="0 0 0 medium">
            <RadioInputGroup
              description={
                <ScreenReaderContent>
                  {I18n.t('Where can teachers create courses?')}
                </ScreenReaderContent>
              }
              name={formatInputName('teachers_can_create_courses_anywhere')}
              defaultValue={currentValues.teachers_can_create_courses_anywhere ? '1' : '0'}
            >
              {locationRadioInputs.map(input => (
                <RadioInput key={input.key} value={input.value} label={input.label} />
              ))}
            </RadioInputGroup>
          </View>
        )}

        <input type="hidden" name={formatInputName('students_can_create_courses')} value={0} />
        <Checkbox
          label={I18n.t('Students')}
          name={formatInputName('students_can_create_courses')}
          value={1}
          checked={isStudentsChecked}
          onChange={e => setStudentsChecked(e.target.checked)}
        />
        {isStudentsChecked && (
          <View as="div" padding="0 0 0 medium">
            <RadioInputGroup
              description={
                <ScreenReaderContent>
                  {I18n.t('Where can students create courses?')}
                </ScreenReaderContent>
              }
              name={formatInputName('students_can_create_courses_anywhere')}
              defaultValue={currentValues.students_can_create_courses_anywhere ? '1' : '0'}
            >
              {locationRadioInputs.map(input => (
                <RadioInput key={input.key} value={input.value} label={input.label} />
              ))}
            </RadioInputGroup>
          </View>
        )}

        <input
          type="hidden"
          name={formatInputName('no_enrollments_can_create_courses')}
          value={0}
        />
        <Checkbox
          label={I18n.t('Users with no enrollments')}
          name={formatInputName('no_enrollments_can_create_courses')}
          value={1}
          checked={isNoEnrollmentsChecked}
          onChange={e => setNoEnrollmentsChecked(e.target.checked)}
        />
      </FormFieldGroup>
    </View>
  )
}

CourseCreationSettings.propTypes = {
  currentValues: PropTypes.shape({
    teachers_can_create_courses: PropTypes.bool.isRequired,
    students_can_create_courses: PropTypes.bool.isRequired,
    no_enrollments_can_create_courses: PropTypes.bool.isRequired,
    teachers_can_create_courses_anywhere: PropTypes.bool.isRequired,
    students_can_create_courses_anywhere: PropTypes.bool.isRequired,
  }).isRequired,
}

export default CourseCreationSettings
