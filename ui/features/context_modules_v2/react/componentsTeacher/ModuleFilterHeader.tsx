/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {IconCheckSolid} from '@instructure/ui-icons'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {ALL_MODULES} from '../utils/utils'

interface ModuleOption {
  id: string
  name: string
  published?: boolean
}

type ModuleViewChangeHandler = (
  event: React.SyntheticEvent<Element, Event>,
  data: {value?: string | number; id?: string},
) => void

interface ModuleFilterHeaderProps {
  moduleOptions: {
    teacherView: ModuleOption[]
    studentView: ModuleOption[]
  }
  handleTeacherChange: ModuleViewChangeHandler
  teacherViewValue: string
  teacherViewEnabled: boolean
  handleStudentChange: ModuleViewChangeHandler
  studentViewValue: string
  studentViewEnabled: boolean
  disabled: boolean
}

const ModuleFilterHeader: React.FC<ModuleFilterHeaderProps> = ({
  moduleOptions,
  handleTeacherChange,
  teacherViewValue,
  teacherViewEnabled,
  handleStudentChange,
  studentViewValue,
  studentViewEnabled,
  disabled,
}) => {
  const renderCheckIfSelected = (selectedValue: string, optionValue: string) =>
    selectedValue === optionValue ? <IconCheckSolid /> : null

  const renderSelect = (
    label: string,
    title: string,
    value: string,
    onChange: ModuleViewChangeHandler,
    options: ModuleOption[],
  ) => {
    return (
      <View>
        <View as="div" margin="0 0 x-small 0">
          <SimpleSelect renderLabel={title} value={value} onChange={onChange} disabled={disabled}>
            <SimpleSelect.Option
              id={ALL_MODULES}
              value={ALL_MODULES}
              renderBeforeLabel={renderCheckIfSelected(value, ALL_MODULES)}
            >
              All Modules
            </SimpleSelect.Option>
            {options.map(({id, name}) => (
              <SimpleSelect.Option
                key={id}
                id={id}
                value={id}
                renderBeforeLabel={renderCheckIfSelected(value, id)}
              >
                {name}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </View>
        <Text variant="contentSmall">Selected module will be visible to {label.toLowerCase()}</Text>
      </View>
    )
  }

  return (
    <Flex
      margin="0 0 medium"
      as="div"
      direction="row"
      wrap="wrap"
      gap="x-small"
      alignItems="stretch"
    >
      {teacherViewEnabled &&
        renderSelect(
          'teachers',
          'Teachers View',
          teacherViewValue,
          handleTeacherChange,
          moduleOptions.teacherView,
        )}
      {studentViewEnabled &&
        renderSelect(
          'students',
          'Students View',
          studentViewValue,
          handleStudentChange,
          moduleOptions.studentView,
        )}
    </Flex>
  )
}

export default ModuleFilterHeader
