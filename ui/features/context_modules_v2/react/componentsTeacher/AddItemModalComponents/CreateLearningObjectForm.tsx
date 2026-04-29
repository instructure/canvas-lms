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
import {QuizEngine, FormState} from '../../utils/types'
import type {Action} from '../../hooks/mutations/useAddModuleItem'
import AddItemFormFieldGroup, {AddItemFormFieldGroupData} from './AddItemFormFieldGroup'

const I18n = createI18nScope('context_modules_v2')

// Types for props
export type CreateLearningObjectFormProps = AddItemFormFieldGroupData & {
  itemType: 'page' | 'quiz' | 'file' | 'external_url' | string
  onChange: (field: string, value: any) => void
  nameError: string | null
  dispatch: React.Dispatch<Action>
  state: FormState
}

export const CreateLearningObjectForm: React.FC<CreateLearningObjectFormProps> = ({
  itemType,
  onChange,
  nameError,
  dispatch,
  state,
  indentValue,
  onIndentChange,
  moduleName,
}: CreateLearningObjectFormProps) => {
  const [folder, setFolder] = useState<string | undefined>(undefined)
  const {courseId, showQuizzesEngineSelection, quizEngine, setQuizEngine} = useContextModule()
  const {folders} = useCourseFolders(courseId)
  const {data: assignmentGroups} = useAssignmentGroups(courseId)
  const defaultAssignmentGroup = assignmentGroups?.assignmentGroups[0]

  const handleFolderChange = useCallback(
    (_e: React.SyntheticEvent, data: {value?: string | number}) => {
      if (data.value === undefined) return
      const selectedFolder = String(data.value)
      setFolder(selectedFolder)
      onChange('folder', selectedFolder)
    },
    [onChange],
  )

  const renderQuizFormFields = () => {
    return (
      <>
        {showQuizzesEngineSelection && (
          <SimpleSelect
            data-testid="create-item-quiz-engine-select"
            renderLabel={I18n.t('Select quiz type')}
            assistiveText={I18n.t(
              'Select the quiz engine. Use the arrow keys to navigate options, then press Enter to confirm.',
            )}
            value={quizEngine}
            onChange={(_e, {value}) => setQuizEngine(value as QuizEngine)}
          >
            <SimpleSelect.Option id="classic" key="classic" value="classic">
              {I18n.t('Quiz Classic')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="new" key="new" value="new">
              {I18n.t('Quiz New')}
            </SimpleSelect.Option>
          </SimpleSelect>
        )}

        <View as="div" padding="medium none none none">
          <SimpleSelect
            renderLabel="Assignment Group"
            value={state.newItem.assignmentGroup}
            defaultValue={defaultAssignmentGroup?._id}
            onChange={(_e, {value}) => onChange('assignmentGroup', value)}
            placeholder={defaultAssignmentGroup?.name}
          >
            {assignmentGroups?.assignmentGroups?.map(group => (
              <SimpleSelect.Option id={group._id} key={group._id} value={group._id}>
                {group.name}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </View>
      </>
    )
  }

  const handleTextInputChange = useCallback(
    (_e: React.SyntheticEvent, val: string) => {
      onChange('name', val)
      if (itemType === 'quiz') {
        onChange('assignmentGroup', state.newItem.assignmentGroup ?? defaultAssignmentGroup?._id)
      }
    },
    [onChange, itemType, state.newItem.assignmentGroup, defaultAssignmentGroup?._id],
  )

  return (
    <AddItemFormFieldGroup
      indentValue={indentValue}
      onIndentChange={onIndentChange}
      moduleName={moduleName}
    >
      {itemType !== 'file' && (
        <TextInput
          renderLabel="Name"
          value={state.newItem.name}
          onChange={handleTextInputChange}
          required
          isRequired={true}
          messages={nameError ? [{text: nameError, type: 'newError'}] : []}
          data-testid="create-learning-object-name-input"
        />
      )}

      {itemType === 'quiz' && renderQuizFormFields()}

      <ModuleFileDrop
        itemType={itemType}
        onChange={onChange}
        dispatch={dispatch}
        shouldAllowMultiple={false}
        nameError={!state.newItem.file?.name && nameError ? nameError : null}
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
      {state.newItem.file?.name && (
        <View as="div" margin="small 0 0 0">
          <Text weight="bold">{I18n.t('Selected file:')}</Text> {state.newItem.file?.name}
        </View>
      )}
    </AddItemFormFieldGroup>
  )
}

export default CreateLearningObjectForm
