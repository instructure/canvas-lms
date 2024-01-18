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
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../../types'
import {PathwayCard, MilestoneCard} from './PathwayBuilderSidebarCards'
import BlankPathwayBox from './BlankPathwayBox'

const Connector = () => {
  return (
    <div style={{margin: '4px 0 -1px 0'}}>
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
      padding="small"
      role="button"
      cursor="pointer"
      onClick={onClick}
      background="primary"
      borderRadius="medium"
      borderWidth="small"
      textAlign="center"
    >
      <View as="div" margin="0 auto">
        <IconPlusLine size="x-small" />
        <View as="div" display="inline-block" margin="0 0 0 small" />
        <Text color="brand">Add Step</Text>
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
  onDeleteStep: (id: string) => void
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
  const childSteps = currentStep ? currentStep.next_milestones : pathway.first_milestones
  const childMilestones = findChildMilestones(pathway.milestones, childSteps)

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
      as="div"
      padding="large medium large x-large"
      background="secondary"
      shadow="topmost"
      minHeight="100%"
      width="480px"
    >
      <Flex as="div" margin="0 0 medium 0" justifyItems="space-between">
        <Text weight="bold">Pathway Builder</Text>
        <CondensedButton onClick={onHideSidebar}>Hide</CondensedButton>
      </Flex>
      <View as="div" textAlign="center">
        <PathwayCard step={pathway} onEdit={handleEditPathway} />
        <Connector />
        {childMilestones.map((step: MilestoneData) => (
          <div key={step.id} style={{marginBottom: '30px'}}>
            <MilestoneCard
              step={step}
              onEdit={handleEditMilestone}
              onDelete={handleDeleteMilestone}
            />
          </div>
        ))}
        {childMilestones.length === 0 && <BlankPathwayBox />}
        <div style={{marginTop: '36px'}} />
        <AddMilestoneButton onClick={onAddStep} />
      </View>
    </View>
  )
}

export default PathwayBuilderSidebar
