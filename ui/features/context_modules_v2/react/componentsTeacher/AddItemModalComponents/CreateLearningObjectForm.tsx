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

import React, {useCallback, useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {RocketSVG} from '@instructure/canvas-media'
import {useCourseFolders} from '../../hooks/queries/useCourseFolders'
import {useContextModule} from '../../hooks/useModuleContext'
import {useAssignmentGroups} from '../../hooks/queries/useAssignmentGroups'

const I18n = createI18nScope('context_modules_v2')

const FILE_DROP_HEIGHT = '350px'

// Types for props
export type CreateLearningObjectFormProps = {
  itemType: 'page' | 'quiz' | 'file' | 'external_url' | string
  onChange: (field: string, value: any) => void
}

export const CreateLearningObjectForm: React.FC<CreateLearningObjectFormProps> = ({
  itemType,
  onChange,
}) => {
  const [name, setName] = useState('')
  const [assignmentGroup, setAssignmentGroup] = useState<string | undefined>(undefined)
  const [folder, setFolder] = useState<string | undefined>(undefined)
  const [file, setFile] = useState<File | null>(null)

  const {courseId} = useContextModule()

  const {folders} = useCourseFolders(courseId)
  const {data: assignmentGroups} = useAssignmentGroups(courseId)

  useEffect(() => {
    if (folders && folders.length > 0 && folder === undefined) {
      const defaultFolder = folders[0]._id
      setFolder(defaultFolder)
      onChange('folder', defaultFolder)
    }
  }, [folders, folder, onChange])

  const handleFileDrop = useCallback(
    (
      accepted: ArrayLike<File | DataTransferItem>,
      _rejected: ArrayLike<File | DataTransferItem>,
      _event: React.DragEvent<Element>,
    ) => {
      if (accepted && accepted.length > 0) {
        const item = accepted[0]
        if (item instanceof File) {
          setFile(item)
          onChange('file', item)
        } else if (item.kind === 'file') {
          const file = item.getAsFile()
          if (file) {
            setFile(file)
            onChange('file', file)
          }
        }
      }
    },
    [onChange],
  )

  const handleFolderChange = useCallback(
    (_e: React.SyntheticEvent, data: {value?: string | number | undefined}) => {
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
      {itemType === 'file' && (
        <>
          <FileDrop
            height={FILE_DROP_HEIGHT}
            shouldAllowMultiple={false}
            onDrop={handleFileDrop}
            renderLabel={
              <Flex direction="column" height="100%" alignItems="center" justifyItems="center">
                <Billboard
                  size="small"
                  hero={<RocketSVG width="3em" height="3em" />}
                  as="div"
                  headingAs="span"
                  headingLevel="h2"
                  heading={I18n.t('Drop files here to upload')}
                  message={<Text color="brand">{I18n.t('or choose files')}</Text>}
                />
              </Flex>
            }
          />
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
          {file && (
            <View as="div" margin="small 0 0 0">
              <Text weight="bold">{I18n.t('Selected file:')}</Text> {file.name}
            </View>
          )}
        </>
      )}
    </View>
  )
}

export default CreateLearningObjectForm
