/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import type {MilestoneData} from '../../../types'
import AddRequirementTray from './AddRequirementTray'

type MilestoneTrayProps = {
  milestone?: MilestoneData
  open: boolean
  variant: 'add' | 'edit'
  onClose: () => void
  onSave: (milestone: MilestoneData) => void
}

const MilestoneTray = ({milestone, open, variant, onClose, onSave}: MilestoneTrayProps) => {
  const [milestoneId] = useState(milestone?.id || uid('ms', 3))
  const [title, setTitle] = useState(milestone?.title || '')
  const [description, setDescription] = useState(milestone?.description || '')
  const [required, setRequired] = useState(milestone?.required || false)
  const [requirements, setRequirements] = useState(milestone?.requirements || [])
  const [reqTrayIsOpen, setReqTrayIsOpen] = useState(false)
  const [reqTrayOpenCount, setReqTrayOpenCount] = useState(0)

  const handleSave = useCallback(() => {
    const newMilestone: MilestoneData = {
      id: milestoneId,
      title,
      description,
      required,
      requirements,
      achievements: [],
      next_milestones: [],
    }
    onSave(newMilestone)
  }, [description, milestoneId, onSave, required, requirements, title])

  const handleNameChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, newName: string) => {
      setTitle(newName)
    },
    []
  )

  const handleDescriptionChange = useCallback((event: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newDescription = event.target.value
    setDescription(newDescription)
  }, [])

  const handleOptionalCheck = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const newRequired = !event.target.checked
    setRequired(newRequired)
  }, [])

  const handleAddRequirementClick = useCallback(() => {
    setReqTrayOpenCount(reqTrayOpenCount + 1)
    setReqTrayIsOpen(true)
  }, [reqTrayOpenCount])

  const handleRequirementTrayClose = useCallback(() => {
    setReqTrayIsOpen(false)
  }, [])

  const handleSaveRequirement = useCallback(
    requirement => {
      setRequirements([...requirements, requirement])
      handleRequirementTrayClose()
    },
    [handleRequirementTrayClose, requirements]
  )

  return (
    <View as="div">
      <Tray
        label={variant === 'add' ? 'Add Step' : 'Edit Step'}
        open={open}
        onDismiss={onClose}
        size="regular"
        placement="end"
      >
        <Flex as="div" direction="column" height="100vh">
          <Flex as="div" padding="small small medium medium">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading level="h2" margin="0 0 small 0">
                {variant === 'add' ? 'Add Step' : 'Edit Step'}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={onClose}
              />
            </Flex.Item>
          </Flex>
          <Flex.Item shouldGrow={true}>
            <View as="div" padding="0 medium medium medium">
              <Alert variant="info" renderCloseButtonLabel="Close" margin="0 0 small 0">
                Steps are building blocks for your pathway. They can represent something as large as
                a course or module, or as small as a assignment.
              </Alert>
              <View as="div" padding="0 0 medium 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  <TextInput
                    isRequired={true}
                    renderLabel="Step Name"
                    value={title}
                    onChange={handleNameChange}
                  />
                </View>
                <View as="div" margin="0 0 small 0">
                  <TextArea
                    label="Step Description"
                    value={description}
                    onChange={handleDescriptionChange}
                  />
                </View>
                <View as="div" margin="0 0 small 0">
                  <Checkbox
                    label="Mark step as optional"
                    value="optional"
                    size="small"
                    checked={!required}
                    variant="toggle"
                    onChange={handleOptionalCheck}
                  />
                </View>
              </View>
              <View as="div" padding="large 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  {requirements.length > 0 ? (
                    <View as="div" margin="small 0">
                      {requirements.map(requirement => (
                        <View
                          as="div"
                          padding="small"
                          background="secondary"
                          borderWidth="small"
                          borderRadius="medium"
                        >
                          <pre key={requirement.id}>{JSON.stringify(requirement, null, 2)}</pre>
                        </View>
                      ))}
                    </View>
                  ) : null}
                  <FormField id="milestone_requiremens" label="Requirements">
                    <Text as="div">
                      Select a criteria learners must complete before continuing progress along the
                      pathway.
                    </Text>
                    <Button
                      renderIcon={IconAddLine}
                      margin="medium 0 0 0"
                      onClick={handleAddRequirementClick}
                    >
                      Add Requirement
                    </Button>
                  </FormField>
                </View>
              </View>
              <View as="div" padding="large 0 0 0">
                add achievements
              </View>
            </View>
          </Flex.Item>
          <Flex.Item align="end" width="100%">
            <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
              <Button onClick={onClose}>Cancel</Button>
              <Button margin="0 0 0 small" onClick={handleSave}>
                Save Step
              </Button>
            </View>
          </Flex.Item>
        </Flex>
      </Tray>

      <AddRequirementTray
        key={reqTrayOpenCount}
        open={reqTrayIsOpen}
        variant="add"
        onClose={handleRequirementTrayClose}
        onSave={handleSaveRequirement}
      />
    </View>
  )
}

export default MilestoneTray
