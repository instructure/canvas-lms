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

// TODO: rename Alert component
import {Alert} from '../../components/Alert/Alert'
import {Alert as AlertFRD} from '@instructure/ui-alerts'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Button} from '@instructure/ui-buttons'
import DateHelper from '../../../../../shared/datetime/dateHelper'
import DirectShareUserModal from '../../../../../shared/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '../../../../../shared/direct-sharing/react/components/DirectShareCourseTray'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionPostToolbar} from '../../components/DiscussionPostToolbar/DiscussionPostToolbar'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!discussion_posts'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import {
  DELETE_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_TOPIC,
  SUBSCRIBE_TO_DISCUSSION_TOPIC
} from '../../../graphql/Mutations'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {SearchContext} from '../../utils/constants'
import {useMutation} from 'react-apollo'
import {isGraded, getSpeedGraderUrl, getEditUrl, getPeerReviewsUrl} from '../../utils'
import {View} from '@instructure/ui-view'

export const DiscussionTopicContainer = ({createDiscussionEntry, ...props}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)
  const [expandedReply, setExpandedReply] = useState(false)

  const {setSearchTerm, filter, setFilter, sort, setSort} = useContext(SearchContext)

  const discussionTopicData = {
    _id: props.discussionTopic._id,
    authorName: props.discussionTopic?.author?.name || '',
    avatarUrl: props.discussionTopic?.author?.avatarUrl || '',
    message: props.discussionTopic?.message || '',
    permissions: props.discussionTopic?.permissions || {},
    postedAt: DateHelper.formatDatetimeForDiscussions(props.discussionTopic?.postedAt),
    published: props.discussionTopic?.published || false,
    subscribed: props.discussionTopic?.subscribed || false,
    title: props.discussionTopic?.title || '',
    unread: props.discussionTopic?.entryCounts?.unreadCount,
    replies: props.discussionTopic?.entryCounts?.repliesCount,
    assignment: props.discussionTopic?.assignment,
    assignmentOverrides: props.discussionTopic?.assignment?.assignmentOverrides?.nodes || [],
    childTopics: props.discussionTopic?.childTopics || [],
    groupSet: props.discussionTopic?.groupSet || false,
    siblingTopics: props.discussionTopic?.rootTopic?.childTopics || [],
    authorRoles: props.discussionTopic?.author?.courseRoles || []
  }

  // TODO: Change this to the new canGrade permission.
  const hasAuthor = !!props.discussionTopic?.author
  const canGrade = discussionTopicData?.permissions?.speedGrader || false
  const canDelete = discussionTopicData?.permissions?.delete || false
  const canReply = discussionTopicData?.permissions?.reply
  const canUpdate = discussionTopicData?.permissions?.update || false
  const canPeerReview = discussionTopicData?.permissions?.peerReview
  const canShowRubric = discussionTopicData?.permissions?.showRubric
  const canAddRubric = discussionTopicData?.permissions?.addRubric
  const canOpenForComments = discussionTopicData?.permissions?.openForComments
  const canCloseForComments = discussionTopicData?.permissions?.closeForComments
  const canCopyAndSendTo = discussionTopicData?.permissions?.copyAndSendTo
  const canModerate = discussionTopicData?.permissions?.moderateForum
  const canUnpublish = props.discussionTopic.canUnpublish

  const canSeeCommons =
    discussionTopicData?.permissions?.manageContent && ENV.discussion_topic_menu_tools?.length > 0

  const canSeeMultipleDueDates = !!(
    discussionTopicData?.permissions?.readAsAdmin &&
    discussionTopicData?.assignmentOverrides?.length > 0
  )

  const defaultDateSet =
    !!discussionTopicData.assignment?.dueAt ||
    !!discussionTopicData.assignment?.lockAt ||
    !!discussionTopicData.assignment?.unlockAt

  const singleOverrideWithNoDefault =
    !defaultDateSet && discussionTopicData.assignmentOverrides.length === 1

  if (isGraded(discussionTopicData.assignment)) {
    if (
      discussionTopicData.assignmentOverrides.length > 0 &&
      canSeeMultipleDueDates &&
      defaultDateSet
    ) {
      discussionTopicData.assignmentOverrides.push({
        dueAt: discussionTopicData.assignment.dueAt,
        unlockAt: discussionTopicData.assignment.unlockAt,
        lockAt: discussionTopicData.assignment.lockAt,
        title: I18n.t('Everyone Else'),
        id: discussionTopicData.assignment.id
      })
    }

    const showSingleOverrideDueDate = () => {
      return discussionTopicData.assignmentOverrides[0]?.dueAt
        ? I18n.t('%{title}: Due %{date}', {
            title: discussionTopicData.assignmentOverrides[0]?.title,
            date: DateHelper.formatDatetimeForDiscussions(
              discussionTopicData.assignmentOverrides[0]?.dueAt
            )
          })
        : I18n.t('%{title}: No Due Date', {
            title: discussionTopicData.assignmentOverrides[0]?.title
          })
    }

    const showDefaultDueDate = () => {
      return discussionTopicData.assignment?.dueAt
        ? I18n.t('Everyone: Due %{dueAtDisplayDate}', {
            dueAtDisplayDate: DateHelper.formatDatetimeForDiscussions(
              props.discussionTopic.assignment?.dueAt
            )
          })
        : I18n.t('No Due Date')
    }

    const showNonAdminDueDate = () => {
      return props.discussionTopic.assignment?.dueAt
        ? I18n.t('Due: %{dueAtDisplayDate}', {
            dueAtDisplayDate: DateHelper.formatDatetimeForDiscussions(
              props.discussionTopic.assignment?.dueAt
            )
          })
        : I18n.t('No Due Date')
    }

    const getDueDateText = () => {
      if (discussionTopicData?.permissions?.readAsAdmin)
        return singleOverrideWithNoDefault ? showSingleOverrideDueDate() : showDefaultDueDate()

      return showNonAdminDueDate()
    }

    discussionTopicData.dueAt = getDueDateText()

    discussionTopicData.pointsPossible = props.discussionTopic.assignment.pointsPossible || 0
  }

  const [deleteDiscussionTopic] = useMutation(DELETE_DISCUSSION_TOPIC, {
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion topic was successfully deleted.'))
      window.location.assign(`/courses/${ENV.course_id}/discussion_topics`)
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error deleting the discussion topic.'))
    }
  })

  const course = {
    id: ENV?.context_asset_string
      ? ENV.context_asset_string.split('_')[0] === 'course'
        ? ENV.context_asset_string.split('_')[1]
        : null
      : null
  }

  const directShareUserModalProps = {
    open: sendToOpen,
    courseId: course.id,
    contentShare: {content_type: 'discussion_topic', content_id: props.discussionTopic._id},
    onDismiss: () => {
      setSendToOpen(false)
    }
  }

  const directShareCourseTrayProps = {
    open: copyToOpen,
    sourceCourseId: course.id,
    contentSelection: {discussion_topics: [props.discussionTopic._id]},
    onDismiss: () => {
      setCopyToOpen(false)
    }
  }

  const [updateDiscussionTopic] = useMutation(UPDATE_DISCUSSION_TOPIC, {
    onCompleted: data => {
      if (!data.updateDiscussionTopic.errors) {
        setOnSuccess(I18n.t('You have successfully updated the discussion topic.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
    }
  })

  const onPublish = () => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        published: !discussionTopicData.published
      }
    })
  }

  const onToggleLocked = locked => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        locked
      }
    })
  }

  const [subscribeToDiscussionTopic] = useMutation(SUBSCRIBE_TO_DISCUSSION_TOPIC, {
    onCompleted: data => {
      if (!data.subscribeToDiscussionTopic.errors) {
        setOnSuccess(
          data.subscribeToDiscussionTopic.discussionTopic.subscribed
            ? I18n.t('You have successfully subscribed to the discussion topic.')
            : I18n.t('You have successfully unsubscribed from the discussion topic.')
        )
      } else {
        setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the discussion topic.'))
    }
  })

  const onSubscribe = () => {
    subscribeToDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        subscribed: !discussionTopicData.subscribed
      }
    })
  }

  const onSearchChange = value => {
    setSearchTerm(value)
  }

  const onViewFilter = (_event, value) => {
    setFilter(value.value)
  }

  const onSortClick = () => {
    sort === 'asc' ? setSort('desc') : setSort('asc')
  }

  const getGroupsMenuTopics = () => {
    if (!discussionTopicData?.permissions?.readAsAdmin) {
      return null
    }
    if (!discussionTopicData?.groupSet) {
      return null
    }
    if (discussionTopicData.childTopics.length > 0) {
      return discussionTopicData.childTopics
    } else if (discussionTopicData.siblingTopics.length > 0) {
      return discussionTopicData.siblingTopics
    } else {
      return null
    }
  }

  return (
    <>
      <div style={{position: 'sticky', top: 0, zIndex: 10, marginTop: '-24px'}}>
        <View as="div" padding="medium 0" background="primary">
          <DiscussionPostToolbar
            childTopics={getGroupsMenuTopics()}
            selectedView={filter}
            sortDirection={sort}
            isCollapsedReplies
            onSearchChange={onSearchChange}
            onViewFilter={onViewFilter}
            onSortClick={onSortClick}
            onCollapseRepliesToggle={() => {}}
            onTopClick={() => {}}
          />
        </View>
      </div>
      {props.discussionTopic.initialPostRequiredForCurrentUser && (
        <AlertFRD renderCloseButtonLabel="Close">
          {I18n.t('You must post before seeing replies.')}
        </AlertFRD>
      )}
      {discussionTopicData?.permissions?.readAsAdmin &&
        discussionTopicData.groupSet &&
        discussionTopicData.assignment?.onlyVisibleToOverrides && (
          <View as="div" margin="none none small" width="80%" data-testid="differentiated-alert">
            <AlertFRD renderCloseButtonLabel="Close">
              {I18n.t(
                'Note: for differentiated group topics, some threads may not have any students assigned.'
              )}
            </AlertFRD>
          </View>
        )}
      <Flex as="div" direction="column">
        <Flex.Item>
          <View
            as="div"
            borderWidth="small"
            borderRadius="medium"
            borderStyle="solid"
            borderColor="primary"
          >
            {isGraded(discussionTopicData.assignment) && (
              <View as="div" padding="none medium none">
                <Alert
                  dueAtDisplayText={discussionTopicData.dueAt}
                  pointsPossible={discussionTopicData.pointsPossible}
                  assignmentOverrides={
                    singleOverrideWithNoDefault ? [] : discussionTopicData.assignmentOverrides
                  }
                  canSeeMultipleDueDates={canSeeMultipleDueDates}
                />
              </View>
            )}

            <Flex direction="column">
              <Flex.Item>
                <Flex
                  direction="row"
                  justifyItems="space-between"
                  padding="medium small none"
                  alignItems="start"
                >
                  <Flex.Item shouldShrink shouldGrow>
                    <PostMessage
                      hasAuthor={hasAuthor}
                      authorName={discussionTopicData.authorName}
                      avatarUrl={discussionTopicData.avatarUrl}
                      timingDisplay={discussionTopicData.postedAt}
                      title={discussionTopicData.title}
                      message={discussionTopicData.message}
                      discussionRoles={discussionTopicData.authorRoles}
                    >
                      {canReply && (
                        <Button
                          color="primary"
                          onClick={() => {
                            setExpandedReply(!expandedReply)
                          }}
                          data-testid="discussion-topic-reply"
                        >
                          {I18n.t('Reply')}
                        </Button>
                      )}
                    </PostMessage>
                  </Flex.Item>
                  <Flex.Item>
                    <PostToolbar
                      onDelete={
                        canDelete
                          ? () => {
                              if (
                                // eslint-disable-next-line no-alert
                                window.confirm(
                                  I18n.t('Are you sure you want to delete this topic?')
                                )
                              ) {
                                deleteDiscussionTopic({
                                  variables: {
                                    id: discussionTopicData._id
                                  }
                                })
                              }
                            }
                          : null
                      }
                      repliesCount={discussionTopicData.replies}
                      unreadCount={discussionTopicData.unread}
                      onSend={
                        canCopyAndSendTo
                          ? () => {
                              setSendToOpen(true)
                            }
                          : null
                      }
                      onCopy={
                        canCopyAndSendTo
                          ? () => {
                              setCopyToOpen(true)
                            }
                          : null
                      }
                      onEdit={
                        canUpdate
                          ? () => {
                              window.location.assign(
                                getEditUrl(ENV.course_id, discussionTopicData._id)
                              )
                            }
                          : null
                      }
                      onTogglePublish={canModerate ? onPublish : null}
                      onToggleSubscription={onSubscribe}
                      onOpenSpeedgrader={
                        canGrade
                          ? () => {
                              window.location.assign(
                                getSpeedGraderUrl(ENV.course_id, discussionTopicData.assignment._id)
                              )
                            }
                          : null
                      }
                      onPeerReviews={
                        canPeerReview
                          ? () => {
                              window.location.assign(
                                getPeerReviewsUrl(ENV.course_id, discussionTopicData.assignment._id)
                              )
                            }
                          : null
                      }
                      onShowRubric={canShowRubric ? () => {} : null}
                      onAddRubric={canAddRubric ? () => {} : null}
                      isPublished={discussionTopicData.published}
                      canUnpublish={canUnpublish}
                      isSubscribed={discussionTopicData.subscribed}
                      onOpenForComments={
                        canOpenForComments
                          ? () => {
                              onToggleLocked(false)
                            }
                          : null
                      }
                      onCloseForComments={
                        canCloseForComments
                          ? () => {
                              onToggleLocked(true)
                            }
                          : null
                      }
                      onShareToCommons={
                        canSeeCommons
                          ? () => {
                              window.location.assign(
                                `${ENV.discussion_topic_menu_tools[0].base_url}&discussion_topics%5B%5D=${discussionTopicData._id}`
                              )
                            }
                          : null
                      }
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item
                shouldShrink
                shouldGrow
                padding={
                  expandedReply ? 'none medium medium xx-large' : 'none medium none xx-large'
                }
                overflowX="hidden"
                overflowY="hidden"
              >
                <DiscussionEdit
                  show={expandedReply}
                  onSubmit={text => {
                    if (createDiscussionEntry) {
                      createDiscussionEntry(text)
                      setExpandedReply(false)
                    }
                  }}
                  onCancel={() => {
                    setExpandedReply(false)
                  }}
                />
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
      </Flex>
      <DirectShareUserModal {...directShareUserModalProps} />
      <DirectShareCourseTray {...directShareCourseTrayProps} />
    </>
  )
}

DiscussionTopicContainer.propTypes = {
  /**
   * Indicates if this Discussion Topic is graded.
   * Providing this property will result in the graded info
   * to be rendered
   */
  discussionTopic: Discussion.shape.isRequired,

  /**
   * Function to be executed to create a Discussion Entry.
   */
  createDiscussionEntry: PropTypes.func
}

export default DiscussionTopicContainer
