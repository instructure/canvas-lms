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
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../../types'
import {PathwayCard, MilestoneCard, BlankPathwayCard} from './PathwayBuilderSidebarCards'
import {readFromLocalStorage, writeToLocalStorage} from '../../../shared/LocalStorage'

const SHOW_ALERT_KEY = 'pathway-add-step-alert'

const Connector = () => {
  return (
    <div style={{margin: '4px 0 -1px 0', textAlign: 'center'}}>
      <svg xmlns="http://www.w3.org/2000/svg" width="6" height="36" viewBox="0 0 6 36" fill="none">
        <circle cx="3" cy="3" r="2" stroke="#6B7780" strokeWidth="2" />
        <circle cx="3" cy="33" r="2" stroke="#6B7780" strokeWidth="2" />
        <path d="M3 6L3 30" stroke="#6B7780" strokeWidth="2" strokeLinecap="square" />
      </svg>
    </div>
  )
}

type AddMilestoneButtonProps = {
  onClick: () => void
}

const AddMilestoneButton = ({onClick}: AddMilestoneButtonProps) => {
  return (
    <View
      as="div"
      margin="medium 0 0 0"
      padding="x-small"
      role="button"
      cursor="pointer"
      onClick={onClick}
      background="primary"
      borderColor="brand"
      borderRadius="medium"
      borderWidth="small"
      textAlign="center"
    >
      <View as="div" margin="0 auto">
        <IconPlusLine size="x-small" color="brand" />
        <View as="div" display="inline-block" margin="0 0 0 x-small">
          <Text color="brand">Add Step</Text>
        </View>
      </View>
    </View>
  )
}

const findChildMilestones = (milestones: MilestoneData[], ids: string[]) => {
  return milestones.filter(m => ids.includes(m.id))
}

type PathwayBuilderSidebarProps = {
  pathway: PathwayDetailData
  currentStep: MilestoneData | null // null => the pathway is the current step
  onAddStep: () => void
  onEditPathway: () => void
  onEditStep: (id: string) => void
  onDeleteStep: (milestoneId: string) => void
  onHideSidebar: () => void
}

const PathwayBuilderSidebar = ({
  currentStep,
  pathway,
  onAddStep,
  onEditPathway,
  onEditStep,
  onDeleteStep,
  onHideSidebar,
}: PathwayBuilderSidebarProps) => {
  const [showAlert, setShowAlert] = useState(() => readFromLocalStorage(SHOW_ALERT_KEY) !== 'false')
  const [firstSteps] = useState(pathway.milestones.length)

  const childSteps = currentStep ? currentStep.next_milestones : pathway.first_milestones
  const childMilestones = findChildMilestones(pathway.milestones, childSteps)

  const handleCloseAlert = useCallback(() => {
    setShowAlert(false)
    writeToLocalStorage(SHOW_ALERT_KEY, 'false')
  }, [])

  const handleEditPathway = useCallback(() => {
    onEditPathway()
  }, [onEditPathway])

  const handleEditMilestone = useCallback(
    (milestoneId: string) => {
      onEditStep(milestoneId)
    },
    [onEditStep]
  )

  const handleDeleteMilestone = useCallback(
    (milestoneId: string) => {
      onDeleteStep(milestoneId)
    },
    [onDeleteStep]
  )

  return (
    <View
      id="pathway-builder-sidebar"
      as="div"
      padding="medium"
      background="secondary"
      shadow="topmost"
      height="100%"
      width="350px"
    >
      <Flex as="div" direction="column" alignItems="stretch" height="100%">
        <Flex.Item overflowX="hidden">
          <Flex as="div" margin="0 0 medium 0" justifyItems="space-between">
            <Text weight="bold">Pathway Builder</Text>
            <CondensedButton onClick={onHideSidebar}>Hide</CondensedButton>
          </Flex>
        </Flex.Item>
        <Flex.Item shouldShrink={true} align="center" overflowY="auto">
          {currentStep === null ? (
            <PathwayCard step={pathway} onEdit={handleEditPathway} />
          ) : (
            <MilestoneCard step={currentStep} variant="root" onEdit={handleEditMilestone} />
          )}
          <Connector />
          {childMilestones.map((step: MilestoneData) => (
            <div key={step.id} style={{marginBottom: '4px'}}>
              <MilestoneCard
                step={step}
                variant="child"
                onEdit={handleEditMilestone}
                onDelete={handleDeleteMilestone}
              />
            </div>
          ))}
          {childMilestones.length === 0 && <BlankPathwayCard />}
          {showAlert && firstSteps === 0 && pathway.milestones.length === 1 && (
            <Alert
              variant="info"
              renderCloseButtonLabel="Close"
              margin="medium 0 0 0"
              onDismiss={handleCloseAlert}
            >
              Select a step to add a prerequisite
            </Alert>
          )}
          <AddMilestoneButton onClick={onAddStep} />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default PathwayBuilderSidebar
