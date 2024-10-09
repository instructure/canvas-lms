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

import React, {useState, useRef} from 'react'
import {Heading} from '@instructure/ui-heading'
import type {TeacherAssignmentType} from '../../graphql/AssignmentTeacherTypes'
import AssignmentPublishButton from './AssignmentPublishButton'
import {Pill} from '@instructure/ui-pill'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconPublishSolid,
  IconEditLine,
  IconUserLine,
  IconSpeedGraderLine,
} from '@instructure/ui-icons'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints'
import {Button} from '@instructure/ui-buttons'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import OptionsMenu from './OptionsMenu'

const I18n = useI18nScope('assignment_teacher_header')

interface HeaderProps {
  assignment: TeacherAssignmentType
  breakpoints: Breakpoints
}

const AssignmentHeader: React.FC<HeaderProps> = props => {
  const isMobile = props.breakpoints.mobileOnly
  const [assignToTray, setAssignToTray] = useState(false)
  const returnFocusTo = useRef(null)
  const speedgraderLink = `/courses/${props.assignment.course.lid}/gradebook/speed_grader?assignment_id=${props.assignment.lid}`
  const editLink = `/courses/${props.assignment.course.lid}/assignments/${props.assignment.lid}/edit`

  return (
    <Flex alignItems="start" direction="column" width="100%">
      <Flex
        direction={isMobile ? 'column' : 'row'}
        alignItems={isMobile ? 'center' : 'start'}
        width="100%"
        justifyItems="space-between"
        id="assignments-2-teacher-header"
      >
        <Flex direction="column" width={!isMobile ? '40%' : '100%'} alignItems="start">
          <Heading data-testid="assignment-name" level="h1">
            {props.assignment.name}
          </Heading>
          <Flex id="submission-status">
            {props.assignment.hasSubmittedSubmissions && (
              <Pill
                renderIcon={<IconPublishSolid />}
                color="success"
                margin={!isMobile ? 'x-small none' : 'medium none none none'}
                data-testid="assignment-status-pill"
              >
                <Text>
                  <Text weight="bold">{I18n.t('Status')} </Text>
                  {I18n.t('Published')}
                </Text>
              </Pill>
            )}
          </Flex>
        </Flex>
        <View
          display={isMobile ? 'block' : 'flex'}
          margin={isMobile ? 'medium none none none' : 'none'}
          width={isMobile ? '100%' : 'auto'}
          id="header-buttons"
        >
          {!props.assignment.hasSubmittedSubmissions && (
            <AssignmentPublishButton
              isPublished={props.assignment.state === 'published'}
              assignmentLid={props.assignment.lid}
              breakpoints={props.breakpoints}
            />
          )}
          {!isMobile && (
            <>
              <Button
                data-testid="edit-button"
                href={editLink}
                renderIcon={<IconEditLine />}
                margin="none none none medium"
              >
                <Text>{I18n.t('Edit')}</Text>
              </Button>
              <Button
                data-testid="assign-to-button"
                ref={returnFocusTo}
                onClick={() => setAssignToTray(true)}
                renderIcon={<IconUserLine />}
                margin="none none none medium"
              >
                <Text>{I18n.t('Assign To')}</Text>
              </Button>
              {props.assignment.state === 'published' && (
                <Button
                  data-testid="speedgrader-button"
                  href={speedgraderLink}
                  target="_blank"
                  renderIcon={<IconSpeedGraderLine />}
                  margin="none none none medium"
                >
                  <Text>{I18n.t('SpeedGrader')}</Text>
                </Button>
              )}
            </>
          )}
          <OptionsMenu assignment={props.assignment} breakpoints={props.breakpoints} />
        </View>
      </Flex>

      <ItemAssignToTray
        open={assignToTray}
        onClose={() => setAssignToTray(false)}
        onDismiss={() => {
          setAssignToTray(false)
          if (returnFocusTo.current) {
            returnFocusTo.current.focus()
          }
        }}
        itemType="assignment"
        iconType="assignment"
        locale={ENV.LOCALE || 'env'}
        timezone={ENV.TIMEZONE || 'UTC'}
        courseId={props.assignment.course.lid}
        itemName={props.assignment.name}
        itemContentId={props.assignment.lid}
        pointsPossible={props.assignment.pointsPossible as number}
      />
    </Flex>
  )
}

export default WithBreakpoints(AssignmentHeader)
