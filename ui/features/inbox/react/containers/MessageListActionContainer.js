/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {COURSES_QUERY} from '../../graphql/Queries'
import {UPDATE_CONVERSATION_PARTICIPANTS} from '../../graphql/Mutations'
import {CourseSelect, ALL_COURSES_ID} from '../components/CourseSelect/CourseSelect'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import {MailboxSelectionDropdown} from '../components/MailboxSelectionDropdown/MailboxSelectionDropdown'
import {MessageActionButtons} from '../components/MessageActionButtons/MessageActionButtons'
import PropTypes from 'prop-types'
import {useQuery, useMutation} from 'react-apollo'
import React, {useContext, useEffect} from 'react'
import {reduceDuplicateCourses} from '../../util/courses_helper'
import {View} from '@instructure/ui-view'
import {AddressBookContainer} from './AddressBookContainer/AddressBookContainer'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../util/utils'

const I18n = useI18nScope('conversations_2')

const MessageListActionContainer = props => {
  const LIMIT_TAG_COUNT = 1
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const userID = ENV.current_user_id?.toString()

  const selectedReadStates = () => {
    const selectedStates =
      props.selectedConversations
        .map(cp =>
          cp.participants?.find(participant => participant.user._id === ENV.current_user?.id)
        )
        .map(node => node?.workflowState) || []
    return selectedStates
  }

  const shouldRenderMarkAsRead = () => selectedReadStates().includes('unread')

  const shouldRenderMarkAsUnread = () => selectedReadStates().includes('read')

  const hasMultipleSelectedMessages = () => selectedReadStates().length > 1

  const hasSelectedConversations = () => props.selectedConversations.length > 0

  const [readStateChangeConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted(data) {
      if (data.updateConversationParticipants.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!'
            },
            {count: props.selectedConversations.length}
          )
        )
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    }
  })

  const {loading, error, data} = useQuery(COURSES_QUERY, {
    variables: {userID}
  })

  const moreCourses = reduceDuplicateCourses(
    data?.legacyNode?.enrollments,
    data?.legacyNode?.favoriteCoursesConnection?.nodes
  )

  const courseSelectorOptions = {
    allCourses: [
      {
        _id: ALL_COURSES_ID,
        contextName: I18n.t('All Courses'),
        assetString: 'all_courses'
      }
    ],
    favoriteCourses: data?.legacyNode?.favoriteCoursesConnection?.nodes,
    moreCourses,
    concludedCourses: [],
    groups: data?.legacyNode?.favoriteGroupsConnection?.nodes
  }

  const doesCourseFilterOptionExist = (id, courseOptions) => {
    return !!Object.values(courseOptions)
      .flat()
      .find(({assetString}) => id === assetString)
  }

  useEffect(() => {
    if (
      !loading &&
      !doesCourseFilterOptionExist(props.activeCourseFilter, courseSelectorOptions) &&
      props.activeCourseFilter !== undefined
    ) {
      props.onCourseFilterSelect(null)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.activeCourseFilter])

  if (loading) {
    return <span />
  }

  if (error) {
    setOnFailure(I18n.t('Unable to load courses menu.'))
  }

  const handleMarkAsUnread = () => {
    readStateChangeConversationParticipants({
      variables: {
        conversationIds: props.selectedConversations.map(convo => convo._id),
        workflowState: 'unread'
      }
    })
  }

  const handleMarkAsRead = () => {
    readStateChangeConversationParticipants({
      variables: {
        conversationIds: props.selectedConversations.map(convo => convo._id),
        workflowState: 'read'
      }
    })
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, tablet: true, desktop: true})}
      props={{
        tablet: {
          addressBookContainer: {
            padding: 'x-small',
            width: '336px'
          },
          courseSelect: {
            padding: 'x-small',
            itemSize: ''
          },
          messageActionButtons: {
            padding: 'x-small'
          }
        },
        desktop: {
          addressBookContainer: {
            padding: 'x-small small x-small x-small',
            width: ''
          },
          courseSelect: {
            padding: 'x-small',
            itemSize: ''
          },
          messageActionButtons: {
            padding: 'x-small x-small x-small medium'
          }
        },
        mobile: {
          addressBookContainer: {
            padding: 'x-small',
            width: ''
          },
          courseSelect: {
            padding: 'none x-small none x-small',
            itemSize: '45%'
          },
          messageActionButtons: {
            padding: 'none x-small none x-small'
          }
        }
      }}
      render={(responsiveProps, matches) => (
        <View
          as="div"
          display="inline-block"
          width="100%"
          margin="none"
          padding="small"
          background="secondary"
        >
          <Flex wrap="wrap">
            <Flex.Item
              shouldGrow={matches.includes('tablet') || matches.includes('mobile')}
              size={responsiveProps.courseSelect.itemSize}
              padding={responsiveProps.courseSelect.padding}
            >
              <CourseSelect
                mainPage
                options={courseSelectorOptions}
                activeCourseFilterID={props.activeCourseFilter}
                onCourseFilterSelect={contextObject => {
                  props.onCourseFilterSelect(contextObject.contextID)
                }}
              />
            </Flex.Item>
            <Flex.Item
              shouldGrow={matches.includes('tablet') || matches.includes('mobile')}
              size={responsiveProps.courseSelect.itemSize}
              padding={responsiveProps.courseSelect.padding}
            >
              <MailboxSelectionDropdown
                activeMailbox={props.activeMailbox}
                onSelect={props.onSelectMailbox}
              />
            </Flex.Item>
            <Flex.Item
              padding={responsiveProps.addressBookContainer.padding}
              shouldGrow
              shouldShrink
              justifyItems="space-between"
            >
              <AddressBookContainer
                onUserFilterSelect={props.onUserFilterSelect}
                width={responsiveProps.addressBookContainer.width}
                limitTagCount={LIMIT_TAG_COUNT}
              />
            </Flex.Item>
            <Flex.Item
              shouldGrow={matches.includes('mobile')}
              padding={responsiveProps.messageActionButtons.padding}
            >
              <MessageActionButtons
                archive={props.displayUnarchiveButton ? undefined : props.onArchive}
                unarchive={props.displayUnarchiveButton ? props.onUnarchive : undefined}
                archiveDisabled={props.archiveDisabled || props.activeMailbox === 'sent'}
                compose={props.onCompose}
                delete={() => props.onDelete()}
                deleteDisabled={props.deleteDisabled}
                forward={props.onForward}
                markAsUnread={handleMarkAsUnread}
                markAsRead={handleMarkAsRead}
                reply={props.onReply}
                replyAll={props.onReplyAll}
                replyDisabled={!hasSelectedConversations() || !props.canReply}
                star={!props.firstConversationIsStarred ? () => props.onStar(true) : null}
                unstar={props.firstConversationIsStarred ? () => props.onStar(false) : null}
                settingsDisabled={!hasSelectedConversations()}
                shouldRenderMarkAsRead={shouldRenderMarkAsRead()}
                shouldRenderMarkAsUnread={shouldRenderMarkAsUnread()}
                hasMultipleSelectedMessages={hasMultipleSelectedMessages()}
              />
            </Flex.Item>
          </Flex>
        </View>
      )}
    />
  )
}

export default MessageListActionContainer

MessageListActionContainer.propTypes = {
  activeMailbox: PropTypes.string,
  onCourseFilterSelect: PropTypes.func,
  onUserFilterSelect: PropTypes.func,
  onSelectMailbox: PropTypes.func,
  onCompose: PropTypes.func,
  selectedConversations: PropTypes.array,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func,
  onForward: PropTypes.func,
  onArchive: PropTypes.func,
  onUnarchive: PropTypes.func,
  deleteDisabled: PropTypes.bool,
  archiveDisabled: PropTypes.bool,
  displayUnarchiveButton: PropTypes.bool,
  firstConversationIsStarred: PropTypes.bool,
  onStar: PropTypes.func,
  onDelete: PropTypes.func,
  activeCourseFilter: PropTypes.string,
  canReply: PropTypes.bool
}

MessageListActionContainer.defaultProps = {
  selectedConversations: [],
  canReply: true
}
