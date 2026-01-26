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
import {View} from '@instructure/ui-view'
import AIExperienceRow from './AIExperienceRow'
import type {AiExperience} from '../types'

interface AIExperienceListProps {
  canManage: boolean
  experiences: AiExperience[]
  onEdit: (id: number) => void
  onTestConversation: (id: number) => void
  onPublishToggle: (id: number, newState: 'published' | 'unpublished') => void
  onDelete: (id: number) => void
}

const AIExperienceList: React.FC<AIExperienceListProps> = ({
  canManage,
  experiences,
  onEdit,
  onTestConversation,
  onPublishToggle,
  onDelete,
}) => {
  return (
    <View
      as="div"
      background="primary"
      borderWidth="small"
      borderColor="primary"
      borderRadius="medium"
    >
      {experiences.map((experience, index) => (
        <React.Fragment key={experience.id}>
          <AIExperienceRow
            canManage={canManage}
            id={experience.id}
            title={experience.title}
            workflowState={experience.workflow_state}
            canUnpublish={experience.can_unpublish ?? true}
            createdAt={experience.created_at}
            submissionStatus={experience.submission_status}
            onEdit={onEdit}
            onTestConversation={onTestConversation}
            onPublishToggle={onPublishToggle}
            onDelete={onDelete}
          />
          {index < experiences.length - 1 && (
            <View as="div" borderWidth="0 0 small 0" borderColor="primary" />
          )}
        </React.Fragment>
      ))}
    </View>
  )
}

export default AIExperienceList
