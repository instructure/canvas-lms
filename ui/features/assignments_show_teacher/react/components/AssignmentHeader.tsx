/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Heading} from '@instructure/ui-heading'
import type {TeacherAssignmentType} from '../../graphql/AssignmentTeacherTypes'
import AssignmentPublishButton from './AssignmentPublishButton'
import {Pill} from '@instructure/ui-pill'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconPublishSolid} from '@instructure/ui-icons'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints'

const I18n = useI18nScope('assignment_teacher_header')

interface HeaderProps {
  assignment: TeacherAssignmentType
  breakpoints: Breakpoints
}

const AssignmentHeader: React.FC<HeaderProps> = props => {
  const isMobile = props.breakpoints.mobileOnly
  return (
    <div className={isMobile ? 'mobile' : 'desktop'}>
      <div id="assignments-2-teacher-header">
        <Heading data-testid="assignment-name" level="h1">
          {props.assignment?.name}
        </Heading>
        <div id="header-buttons">
          {!props.assignment.hasSubmittedSubmissions && (
            <AssignmentPublishButton
              isPublished={props.assignment.state === 'published'}
              assignmentLid={props.assignment.lid}
              breakpoints={props.breakpoints}
            />
          )}
        </div>
      </div>

      <div id="submission-status">
        {props.assignment.hasSubmittedSubmissions && (
          <Pill
            statusLabel="Status"
            renderIcon={<IconPublishSolid />}
            color="success"
            margin="x-small auto"
            data-testid="assignment-status-pill"
          >
            {I18n.t('Published')}
          </Pill>
        )}
      </div>
    </div>
  )
}

export default WithBreakpoints(AssignmentHeader)
