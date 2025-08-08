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

import React, {useState, useCallback} from 'react'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {useCourseFolders} from '../../hooks/queries/useCourseFolders'
import {useContextModule} from '../../hooks/useModuleContext'
import {useAssignmentGroups} from '../../hooks/queries/useAssignmentGroups'
import ModuleFileDrop from '../AddItemModalComponents/ModuleFileDrop'

const I18n = createI18nScope('context_modules_v2')

// Types for props
export type CreateLearningObjectFormProps = {
  itemType: 'page' | 'quiz' | 'file' | 'external_url' | string
  onChange: (field: string, value: any) => void
  nameError: string | null
  setName: (name: string) => void
  name: string
}

export const CreateLearningObjectForm: React.FC<CreateLearningObjectFormProps> = ({
  itemType,
  onChange,
  nameError,
  setName,
  name,
}) => {
  const [assignmentGroup, setAssignmentGroup] = useState<string | undefined>(undefined)
  const [folder, setFolder] = useState<string | undefined>(undefined)
  const [file, setFile] = useState<File | null>(null)

  const {courseId} = useContextModule()
  const {folders} = useCourseFolders(courseId)
  const {data: assignmentGroups} = useAssignmentGroups(courseId)

  const handleFolderChange = useCallback(
    (_e: React.SyntheticEvent, data: {value?: string | number}) => {
      if (data.value === undefined) return
      const selectedFolder = String(data.value)
      setFolder(selectedFolder)
      onChange('folder', selectedFolder)
    },
    [onChange],
  )

  return (
    <View as="form" padding="small" display="block">
      {itemType !== 'file' && (
        <TextInput
          renderLabel="Name"
          value={name}
          onChange={(_e, val) => {
            setName(val)
            onChange('name', val)
          }}
          margin="0 0 medium 0"
          required
          isRequired={true}
          messages={nameError ? [{text: nameError, type: 'newError'}] : []}
        />
      )}
      {itemType === 'quiz' && (
        <SimpleSelect
          renderLabel="Assignment Group"
          value={assignmentGroup}
          onChange={(_e, {value}) => {
            setAssignmentGroup(String(value))
            onChange('assignmentGroup', value)
          }}
          placeholder="Select assignment group"
        >
          {assignmentGroups?.assignmentGroups?.map(group => (
            <SimpleSelect.Option id={group._id} key={group._id} value={group._id}>
              {group.name}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      )}
      <ModuleFileDrop
        itemType={itemType}
        onChange={onChange}
        setFile={setFile}
        shouldAllowMultiple={false}
      />
      {itemType === 'file' && (
        <View as="div" margin="medium 0 0 0">
          <SimpleSelect
            renderLabel="Folder"
            value={folder}
            onChange={handleFolderChange}
            placeholder="Select folder"
          >
            {folders?.map(f => (
              <SimpleSelect.Option id={f._id} key={f._id} value={f._id}>
                {f.name}
              </SimpleSelect.Option>
            ))}
            {folders?.length === 0 && (
              <SimpleSelect.Option id="no-folders" value="">
                {I18n.t('No folders available')}
              </SimpleSelect.Option>
            )}
          </SimpleSelect>
        </View>
      )}
      {file && (
        <View as="div" margin="small 0 0 0">
          <Text weight="bold">{I18n.t('Selected file:')}</Text> {file.name}
        </View>
      )}
    </View>
  )
}

export default CreateLearningObjectForm
