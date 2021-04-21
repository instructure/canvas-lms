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

import {ComposeInputWrapper} from 'jsx/canvas_inbox/components/ComposeInputWrapper/ComposeInputWrapper'
import {CourseSelect} from 'jsx/canvas_inbox/components/CourseSelect/CourseSelect'
import I18n from 'i18n!conversations_2'
import {IndividualMessageCheckbox} from 'jsx/canvas_inbox/components/IndividualMessageCheckbox/IndividualMessageCheckbox'
import PropTypes from 'prop-types'
import React from 'react'
import {reduceDuplicateCourses} from '../../helpers/courses_helper'
import {SubjectInput} from 'jsx/canvas_inbox/components/SubjectInput/SubjectInput'

import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

const HeaderInputs = (props) => {
  let moreCourses
  if (!props.isReply) {
    moreCourses = reduceDuplicateCourses(
      props.courses.enrollments,
      props.courses.favoriteCoursesConnection.nodes
    )
  }

  return (
    <Flex direction="column" width="100%" height="100%" padding="small">
      <Flex.Item>
        <ComposeInputWrapper
          title={
            <PresentationContent>
              <Text size="small">{I18n.t('Course')}</Text>
            </PresentationContent>
          }
          input={
            props.isReply ? (
              <Text size="small">{props.contextName}</Text>
            ) : (
              <CourseSelect
                mainPage={false}
                options={{
                  favoriteCourses: props.courses?.favoriteCoursesConnection.nodes,
                  moreCourses,
                  concludedCourses: [],
                  groups: props.courses?.favoriteGroupsConnection.nodes,
                }}
                onCourseFilterSelect={props.onContextSelect}
              />
            )
          }
          shouldGrow={false}
        />
      </Flex.Item>
      {props.isReply ? (
        <ComposeInputWrapper
          title={
            <PresentationContent>
              <Text size="small">{I18n.t('Subject')}</Text>
            </PresentationContent>
          }
          input={<Text size="small">{props.subject}</Text>}
        />
      ) : (
        <SubjectInput onChange={props.onSubjectChange} value={props.subject} />
      )}
      {!props.isReply && (
        <Flex.Item>
          <ComposeInputWrapper
            shouldGrow
            input={
              <IndividualMessageCheckbox
                onChange={props.onSendIndividualMessagesChange}
                checked={props.sendIndividualMessages}
              />
            }
          />
        </Flex.Item>
      )}
    </Flex>
  )
}

HeaderInputs.propTypes = {
  contextName: PropTypes.string,
  courses: PropTypes.object,
  isReply: PropTypes.bool,
  onContextSelect: PropTypes.func,
  onSendIndividualMessagesChange: PropTypes.func,
  onSubjectChange: PropTypes.func,
  sendIndividualMessages: PropTypes.bool,
  subject: PropTypes.string,
}

export default HeaderInputs
