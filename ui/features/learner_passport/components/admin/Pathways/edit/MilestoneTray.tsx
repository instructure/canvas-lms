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

import React, {useCallback, useContext, useEffect, useState} from 'react'
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
import type {MilestoneData, RequirementData} from '../../../types'
import AddRequirementTray from './AddRequirementTray'
import AddBadgeTray, {renderBadges} from './AddBadgeTray'
import MilestoneRequirementCard from './requirements/MilestoneRequirementCard'
import {readFromLocalStorage, writeToLocalStorage} from '../../../shared/LocalStorage'
import {DataContext} from '../PathwayEditDataContext'

const SHOW_ALERT_KEY = 'passport_showMilestoneTrayAlert'

type MilestoneTrayProps = {
  milestone: MilestoneData
  open: boolean
  variant: 'add' | 'edit'
  onClose: () => void
  onSave: (milestone: MilestoneData) => void
}

const MilestoneTray = ({milestone, open, variant, onClose, onSave}: MilestoneTrayProps) => {
  const {allBadges} = useContext(DataContext)
  const [milestoneId, setMilestoneId] = useState(milestone.id)
  const [title, setTitle] = useState(milestone.title)
  const [description, setDescription] = useState(milestone.description)
  const [required, setRequired] = useState(milestone.required)
  const [requirements, setRequirements] = useState(milestone.requirements)
  const [activeRequirement, setActiveRequirement] = useState<RequirementData | undefined>(undefined)
  const [reqTrayOpen, setReqTrayOpen] = useState(false)
  const [reqTrayKey, setReqTrayKey] = useState(0)
  const [addBadgeTrayOpen, setAddBadgeTrayOpen] = useState(false)
  const [selectedBadgeId, setSelectedBadgeId] = useState<string | null>(milestone.completion_award)
  const [validName, setValidName] = useState(true)
  const [showAlert, setShowAlert] = useState(() => readFromLocalStorage(SHOW_ALERT_KEY) !== 'false')

  useEffect(() => {
    if (milestoneId !== milestone.id) {
      setMilestoneId(milestone.id)
      setTitle(milestone.title)
      setDescription(milestone.description)
      setRequired(milestone.required)
      setRequirements(milestone.requirements)
    }
  }, [
    milestone.description,
    milestone.id,
    milestone.required,
    milestone.requirements,
    milestone.title,
    milestoneId,
  ])

  const handleCloseAlert = useCallback(() => {
    setShowAlert(false)
    writeToLocalStorage(SHOW_ALERT_KEY, 'false')
  }, [])

  const handleTrayClosed = useCallback(() => {
    setReqTrayOpen(false)
    setAddBadgeTrayOpen(false)
  }, [])

  const handleCancel = useCallback(() => {
    setReqTrayOpen(false)
    onClose()
  }, [onClose])

  const handleSave = useCallback(() => {
    if (!title) return
    setReqTrayOpen(false)
    const newMilestone: MilestoneData = {
      id: milestoneId,
      title,
      description,
      required,
      requirements,
      completion_award: selectedBadgeId,
      next_milestones: milestone.next_milestones,
    }
    onSave(newMilestone)
  }, [
    description,
    milestone.next_milestones,
    milestoneId,
    onSave,
    required,
    requirements,
    selectedBadgeId,
    title,
  ])

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
    setActiveRequirement(undefined)
    setReqTrayKey(Date.now())
    setReqTrayOpen(true)
  }, [])

  const handleRequirementTrayClose = useCallback(() => {
    setReqTrayOpen(false)
  }, [])

  const handleSaveRequirement = useCallback(
    newRequirement => {
      if (activeRequirement) {
        const prevVersion = requirements.findIndex(r => r.id === activeRequirement.id)
        const newRequirements = [...requirements]
        newRequirements.splice(prevVersion, 1, newRequirement)
        setRequirements(newRequirements)
      } else {
        setRequirements([...requirements, newRequirement])
      }
      handleRequirementTrayClose()
    },
    [activeRequirement, handleRequirementTrayClose, requirements]
  )

  const handleEditRequirement = useCallback((requirement: RequirementData) => {
    setActiveRequirement(requirement)
    setReqTrayKey(Date.now())
    setReqTrayOpen(true)
  }, [])

  const handleDeleteRequirement = useCallback(
    (requirement: RequirementData) => {
      const newRequirements = [...requirements].filter(r => r.id !== requirement.id)
      setRequirements(newRequirements)
    },
    [requirements]
  )

  const handleAddAchievementClick = useCallback(() => {
    setAddBadgeTrayOpen(true)
  }, [])

  const handleSaveBadge = useCallback((badgeId: string | null) => {
    setSelectedBadgeId(badgeId)
    setAddBadgeTrayOpen(false)
  }, [])

  const handleRemoveBadge = useCallback(() => {
    setSelectedBadgeId(null)
  }, [])

  return (
    <View as="div">
      <Tray
        label={variant === 'add' ? 'Add Step' : 'Edit Step'}
        open={open}
        onClose={handleTrayClosed}
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
                onClick={handleCancel}
              />
            </Flex.Item>
          </Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="auto">
            <View as="div" padding="0 medium medium medium">
              {showAlert && (
                <Alert
                  variant="info"
                  renderCloseButtonLabel="Close"
                  margin="0 0 small 0"
                  onDismiss={handleCloseAlert}
                >
                  Steps are building blocks for your pathway. They can represent something as large
                  as a course or module, or as small as a assignment.
                </Alert>
              )}
              <View as="div" padding="0 0 medium 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  <TextInput
                    isRequired={true}
                    renderLabel="Step Name"
                    value={title}
                    onBlur={() => setValidName(!!title)}
                    onChange={handleNameChange}
                    messages={
                      validName ? undefined : [{text: 'Step name is Required', type: 'error'}]
                    }
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
                <FormField id="milestone_requiremens" label="Requirements">
                  <Text as="div">
                    Select a criteria learners must complete before continuing progress along the
                    pathway.
                  </Text>
                  <View as="div" margin="0 0 small 0">
                    {requirements.length > 0 ? (
                      <View as="div" margin="small 0">
                        {requirements.map(requirement => (
                          <View
                            key={requirement.id}
                            as="div"
                            padding="small"
                            background="secondary"
                            borderWidth="small"
                            borderRadius="medium"
                            margin="0 0 small 0"
                          >
                            <MilestoneRequirementCard
                              key={requirement.id}
                              variant="edit"
                              requirement={requirement}
                              onEdit={() => handleEditRequirement(requirement)}
                              onDelete={() => handleDeleteRequirement(requirement)}
                            />
                          </View>
                        ))}
                      </View>
                    ) : null}

                    <Button
                      renderIcon={IconAddLine}
                      margin="small 0 0 0"
                      onClick={handleAddRequirementClick}
                    >
                      Add Requirement
                    </Button>
                  </View>
                </FormField>
              </View>
              <View as="div" padding="large 0 0 0">
                <FormField id="milestone_achievements" label="Achievements">
                  <Text as="div">
                    Add a badge or certificate to this milestone to recognize a key accomplishment.
                  </Text>
                  {selectedBadgeId && renderBadges(allBadges, selectedBadgeId, handleRemoveBadge)}
                  <Button
                    interaction={selectedBadgeId ? 'disabled' : 'enabled'}
                    renderIcon={IconAddLine}
                    margin="small 0 0 0"
                    onClick={handleAddAchievementClick}
                  >
                    Add Achievement
                  </Button>
                </FormField>
              </View>
            </View>
          </Flex.Item>
          <Flex.Item align="end" width="100%">
            <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
              <Button onClick={handleCancel}>Cancel</Button>
              <Button margin="0 0 0 small" onClick={handleSave}>
                Save Step
              </Button>
            </View>
          </Flex.Item>
        </Flex>
      </Tray>

      <AddRequirementTray
        key={reqTrayKey}
        requirement={activeRequirement}
        open={reqTrayOpen}
        variant="add"
        onClose={handleRequirementTrayClose}
        onSave={handleSaveRequirement}
      />
      <AddBadgeTray
        selectedBadgeId={selectedBadgeId}
        open={addBadgeTrayOpen}
        onClose={() => setAddBadgeTrayOpen(false)}
        onSave={handleSaveBadge}
      />
    </View>
  )
}

export default MilestoneTray
