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

import {ComposeInputWrapper} from '../../components/ComposeInputWrapper/ComposeInputWrapper'
import {CourseSelect} from '../../components/CourseSelect/CourseSelect'
import I18n from 'i18n!conversations_2'
import {IndividualMessageCheckbox} from '../../components/IndividualMessageCheckbox/IndividualMessageCheckbox'
import {FacultyJournalCheckBox} from '../../components/FacultyJournalCheckbox/FacultyJournalCheckbox'
import PropTypes from 'prop-types'
import React from 'react'
import {reduceDuplicateCourses} from '../../../util/courses_helper'
import {SubjectInput} from '../../components/SubjectInput/SubjectInput'

import {Flex} from '@instructure/ui-flex'
import {MediaAttachment} from '../../components/MediaAttachment/MediaAttachment'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {AddressBookContainer} from '../AddressBookContainer/AddressBookContainer'

const HeaderInputs = props => {
  let moreCourses
  if (!props.isReply && !props.isForward) {
    moreCourses = reduceDuplicateCourses(
      props.courses.enrollments,
      props.courses.favoriteCoursesConnection.nodes
    )
  }

  const canAddUserNote =
    ENV.CONVERSATIONS.NOTES_ENABLED &&
    (ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_ACCOUNT ||
      Object.values(ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_COURSES).some(course => !!course))

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
            props.isReply || props.isForward ? (
              <Text size="small">{props.contextName}</Text>
            ) : (
              <CourseSelect
                mainPage={false}
                options={{
                  favoriteCourses: props.courses?.favoriteCoursesConnection.nodes,
                  moreCourses,
                  concludedCourses: [],
                  groups: props.courses?.favoriteGroupsConnection.nodes
                }}
                onCourseFilterSelect={props.onContextSelect}
              />
            )
          }
        />
      </Flex.Item>
      {!props.isReply && (
        <Flex.Item>
          <ComposeInputWrapper
            title={
              <PresentationContent>
                <Text size="small">{I18n.t('To')}</Text>
              </PresentationContent>
            }
            input={
              <AddressBookContainer
                width="100%"
                open={props.addressBookContainerOpen}
                onSelectedIdsChange={ids => {
                  props.onSelectedIdsChange(ids)
                }}
              />
            }
            shouldGrow
          />
        </Flex.Item>
      )}
      {canAddUserNote && (
        <Flex.Item>
          <ComposeInputWrapper
            shouldGrow
            input={
              <FacultyJournalCheckBox onChange={props.onUserNoteChange} checked={props.userNote} />
            }
          />
        </Flex.Item>
      )}
      {!props.isReply && !props.isForward && (
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
      {props.isReply || props.isForward ? (
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
      {props.mediaAttachmentTitle && (
        <Flex.Item data-testid="media-attachment">
          <ComposeInputWrapper
            shouldGrow
            input={
              <MediaAttachment
                mediaTitle={props.mediaAttachmentTitle}
                onRemoveMedia={props.onRemoveMediaComment}
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
  isForward: PropTypes.bool,
  onContextSelect: PropTypes.func,
  onSelectedIdsChange: PropTypes.func,
  onUserNoteChange: PropTypes.func,
  onSendIndividualMessagesChange: PropTypes.func,
  onSubjectChange: PropTypes.func,
  userNote: PropTypes.bool,
  sendIndividualMessages: PropTypes.bool,
  subject: PropTypes.string,
  mediaAttachmentTitle: PropTypes.string,
  onRemoveMediaComment: PropTypes.func,
  /**
   * Bool to control open/closed state of the AddressBookContainer menu for testing
   */
  addressBookContainerOpen: PropTypes.bool
}

export default HeaderInputs
