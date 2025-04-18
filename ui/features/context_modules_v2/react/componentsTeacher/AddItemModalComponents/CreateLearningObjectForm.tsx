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

import React, {useState} from 'react'
import {Billboard} from '@instructure/ui-billboard'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {RocketSVG} from '@instructure/canvas-media'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

// Types for props
interface CreateLearningObjectFormProps {
  itemType: string
  onChange: (field: string, value: any) => void
  assignmentGroups?: {id: string; name: string; _id: string}[]
  folders?: {id: string; name: string}[]
}

const FILE_DROP_HEIGHT = 350

export const CreateLearningObjectForm: React.FC<CreateLearningObjectFormProps> = ({
  itemType,
  onChange,
  assignmentGroups = [],
  folders = [],
}) => {
  const [name, setName] = useState('')
  const [assignmentGroup, setAssignmentGroup] = useState<string | undefined>(undefined)
  const [folder, setFolder] = useState<string | undefined>(undefined)
  const [file, setFile] = useState<File | null>(null)

  // Handle file drop
  const handleFileDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      setFile(e.dataTransfer.files[0])
      onChange('file', e.dataTransfer.files[0])
    }
  }

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0])
      onChange('file', e.target.files[0])
    }
  }

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
          {assignmentGroups.map(group => (
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
            shouldAllowMultiple={true}
            // Called when dropping files or when clicking,
            // after the file dialog window exits successfully
            onDrop={() => {}}
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
              onChange={(_e, {value}) => {}}
              placeholder="Select folder"
            >
              {folders.map(f => (
                <SimpleSelect.Option id={f.id} key={f.id} value={f.id}>
                  {f.name}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
          </View>
        </>
      )}
    </View>
  )
}

export default CreateLearningObjectForm
