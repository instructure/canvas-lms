/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

import {AssignmentSubmissionTypeSelectionResourceLinkCard} from './AssignmentSubmissionTypeSelectionResourceLinkCard'
import {AssignmentSubmissionTypeSelectionLaunchButton} from './AssignmentSubmissionTypeSelectionLaunchButton'

export type AssignmentSubmissionTypeContainerProps = {
  tool: {
    developer_key?: {
      global_id: string
    }
    id: string
    title: string
    description?: string
    icon_url?: string
  }
  resource?: {
    title: string
  }
  onLaunchButtonClick: () => void
  onRemoveResource: () => void
}

declare const ENV: GlobalEnv & {
  ASSIGNMENT_SUBMISSION_TYPE_CARD_ENABLED: boolean
}

export function AssignmentSubmissionTypeContainer(props: AssignmentSubmissionTypeContainerProps) {
  const {resource, tool, onLaunchButtonClick, onRemoveResource} = props

  const [removedResource, setRemovedResource] = useState(false)

  return (
    <>
      {ENV.ASSIGNMENT_SUBMISSION_TYPE_CARD_ENABLED ? (
        <>
          {resource?.title && !removedResource ? (
            <AssignmentSubmissionTypeSelectionResourceLinkCard
              tool={tool}
              resourceTitle={resource.title}
              onCloseButton={() => {
                setRemovedResource(true)
                onRemoveResource()
              }}
            />
          ) : (
            <AssignmentSubmissionTypeSelectionLaunchButton
              tool={tool}
              onClick={() => {
                setRemovedResource(false)
                onLaunchButtonClick()
              }}
            />
          )}
        </>
      ) : (
        <AssignmentSubmissionTypeSelectionLaunchButton
          tool={tool}
          onClick={() => {
            setRemovedResource(false)
            onLaunchButtonClick()
          }}
        />
      )}
    </>
  )
}
