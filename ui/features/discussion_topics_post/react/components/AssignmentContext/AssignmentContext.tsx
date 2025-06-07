/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'

import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Responsive} from '@instructure/ui-responsive'
import {DueDatesForParticipantList} from '../DueDatesForParticipantList/DueDatesForParticipantList'

const I18n = createI18nScope('discussion_posts')

interface AssignmentOverride {
  set?: {
    __typename?: string
  }
  [key: string]: any
}

interface AssignmentContextProps {
  group?: string
  assignmentOverride?: AssignmentOverride | null
}

export function AssignmentContext({group = '', assignmentOverride = null}: AssignmentContextProps) {
  let groupDisplayText = null
  if (group) {
    groupDisplayText = group
  } else if (assignmentOverride?.set?.__typename !== 'AdhocStudents') {
    groupDisplayText = I18n.t('Everyone')
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true}) as any}
      props={{
        tablet: {
          textSize: 'x-small',
          displayText: null,
        },
        desktop: {
          textSize: 'small',
          displayText: groupDisplayText,
        },
      }}
      render={(responsiveProps: any) => {
        return responsiveProps?.displayText ? (
          <DueDatesForParticipantList
            textSize={responsiveProps.textSize}
            assignmentOverride={assignmentOverride}
            overrideTitle={responsiveProps.displayText}
          />
        ) : null
      }}
    />
  )
}
