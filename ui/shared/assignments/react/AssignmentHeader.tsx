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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconPublishSolid,
  IconEditLine,
  IconUserLine,
  IconSpeedGraderLine,
  IconNoLine,
} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import AssignmentPublishButton from './AssignmentPublishButton'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import OptionsMenu from './OptionsMenu'
import {type Breakpoints} from '@canvas/with-breakpoints'
import type {TeacherAssignmentType} from '../graphql/teacher/AssignmentTeacherTypes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ASSIGNMENT_VIEW_TYPES} from './AssignmentTypes'

const I18n = createI18nScope('assignment_teacher_header')

interface HeaderProps {
  type: string
  assignment: TeacherAssignmentType
  breakpoints: Breakpoints
}

const AssignmentHeader: React.FC<HeaderProps> = ({type, assignment, breakpoints}) => {
  const isMobile = breakpoints.mobileOnly
  const [assignToTray, setAssignToTray] = useState(false)
  const returnFocusTo = useRef(null)
  const speedgraderLink = `/courses/${assignment.course?.lid}/gradebook/speed_grader?assignment_id=${assignment.lid}`
  const editLink = `/courses/${assignment.course?.lid}/assignments/${assignment.lid}/edit`
  const isSavedView = type === ASSIGNMENT_VIEW_TYPES.SAVED

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
          <Heading data-testid="assignment-heading" level="h1">
            {type === ASSIGNMENT_VIEW_TYPES.EDIT
              ? I18n.t('Edit Assignment')
              : type === ASSIGNMENT_VIEW_TYPES.CREATE
                ? I18n.t('Create Assignment')
                : assignment.name}
          </Heading>
          <Flex id="submission-status">
            {isSavedView && assignment.hasSubmittedSubmissions && (
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
          {isSavedView && !assignment.hasSubmittedSubmissions && (
            <AssignmentPublishButton
              isPublished={assignment.state === 'published'}
              // @ts-expect-error
              assignmentLid={assignment.lid}
              breakpoints={breakpoints}
            />
          )}
          {!isSavedView && (
            <Flex>
              {assignment.state === 'published' ? (
                <IconPublishSolid color="success" />
              ) : (
                <IconNoLine />
              )}
              <Flex margin="0 0 0 x-small">
                {assignment.state === 'published' ? (
                  <Text color="success" weight="bold">
                    {I18n.t('Published')}
                  </Text>
                ) : (
                  <Text>{I18n.t('Unpublished')}</Text>
                )}
              </Flex>
            </Flex>
          )}
          {!isMobile && isSavedView && (
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
              {assignment.state === 'published' && (
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
          <OptionsMenu type={type} assignment={assignment} breakpoints={breakpoints} />
        </View>
      </Flex>

      <ItemAssignToTray
        open={assignToTray}
        onClose={() => setAssignToTray(false)}
        onDismiss={() => {
          setAssignToTray(false)
          if (returnFocusTo.current) {
            // @ts-expect-error
            returnFocusTo.current.focus()
          }
        }}
        itemType="assignment"
        iconType="assignment"
        locale={ENV.LOCALE || 'env'}
        timezone={ENV.TIMEZONE || 'UTC'}
        courseId={assignment.course?.lid}
        // @ts-expect-error
        itemName={assignment.name}
        itemContentId={assignment?.lid}
        pointsPossible={assignment.pointsPossible as number}
      />
    </Flex>
  )
}

export default AssignmentHeader
