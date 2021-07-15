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
import {Link} from '@instructure/ui-link'
import DateHelper from '../../../../../shared/datetime/dateHelper'
import DirectShareUserModal from '../../../../../shared/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '../../../../../shared/direct-sharing/react/components/DirectShareCourseTray'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import I18n from 'i18n!discussion_posts'
import {PeerReview} from '../../components/PeerReview/PeerReview'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import {
  DELETE_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_TOPIC,
  SUBSCRIBE_TO_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_READ_STATE
} from '../../../graphql/Mutations'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {SearchContext} from '../../utils/constants'
import {useMutation} from 'react-apollo'
import {isGraded, getReviewLinkUrl, resolveAuthorRoles} from '../../utils'
import {View} from '@instructure/ui-view'
import {PostToolbarContainer} from '../PostToolbarContainer/PostToolbarContainer'

export const DiscussionTopicContainer = ({createDiscussionEntry, ...props}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)
  const [expandedReply, setExpandedReply] = useState(false)

  const {searchTerm} = useContext(SearchContext)

  const discussionTopicData = {
    _id: props.discussionTopic._id,
    authorName: props.discussionTopic?.author?.name || '',
    authorId: props.discussionTopic?.author?._id,
    editorName: props.discussionTopic?.editor?.name,
    editorId: props.discussionTopic?.editor?._id,
    avatarUrl: props.discussionTopic?.author?.avatarUrl || '',
    message: props.discussionTopic?.message || '',
    permissions: props.discussionTopic?.permissions || {},
    postedAt: DateHelper.formatDatetimeForDiscussions(props.discussionTopic?.postedAt),
    updatedAt: DateHelper.formatDatetimeForDiscussions(props.discussionTopic?.updatedAt),
    published: props.discussionTopic?.published || false,
    subscribed: props.discussionTopic?.subscribed || false,
    title: props.discussionTopic?.title || '',
    unread: props.discussionTopic?.entryCounts?.unreadCount,
    replies: props.discussionTopic?.entryCounts?.repliesCount,
    assignment: props.discussionTopic?.assignment,
    assignmentOverrides: props.discussionTopic?.assignment?.assignmentOverrides?.nodes || [],
    attachmentDisplayName: props.discussionTopic?.attachment?.displayName || null,
    attachmentUrl: props.discussionTopic?.attachment?.url || null,
    childTopics: props.discussionTopic?.childTopics || [],
    groupSet: props.discussionTopic?.groupSet || false,
    siblingTopics: props.discussionTopic?.rootTopic?.childTopics || [],
    authorRoles: props.discussionTopic?.author?.courseRoles || []
  }

  // TODO: Change this to the new canGrade permission.
  const hasAuthor = !!props.discussionTopic?.author
  const showEditedBy =
    !!discussionTopicData.editorId && discussionTopicData.editorId !== discussionTopicData.authorId
  const canReply = discussionTopicData?.permissions?.reply
  const canCloseForComments =
    discussionTopicData?.permissions?.closeForComments && !props.discussionTopic?.rootTopic
  const requiresInitialPost = props.discussionTopic.initialPostRequiredForCurrentUser
  const canUnpublish = props.discussionTopic.canUnpublish

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
      discussionTopicData.assignmentOverrides = discussionTopicData.assignmentOverrides.concat({
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

  const [updateDiscussionReadState] = useMutation(UPDATE_DISCUSSION_READ_STATE, {
    onCompleted: data => {
      if (!data.updateDiscussionReadState.errors) {
        setOnSuccess(I18n.t('You have successfully marked all as read.'))
      } else {
        setOnFailure(I18n.t('There was an unexpected error marking all as read.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error marking all as read.'))
    }
  })

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

  const onMarkAllAsRead = () => {
    updateDiscussionReadState({
      variables: {
        discussionTopicId: discussionTopicData._id,
        read: true
      }
    })
  }

  const onSubscribe = () => {
    subscribeToDiscussionTopic({
      variables: {
        discussionTopicId: discussionTopicData._id,
        subscribed: !discussionTopicData.subscribed
      }
    })
  }

  return (
    <>
      {discussionTopicData?.initialPostRequiredForCurrentUser && (
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
      {!searchTerm && (
        <Flex as="div" direction="column" data-testid="discussion-topic-container">
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
                  {props.discussionTopic.assignment?.assessmentRequestsForCurrentUser?.map(
                    assessmentRequest => (
                      <PeerReview
                        key={assessmentRequest._id}
                        dueAtDisplayText={DateHelper.formatDatetimeForDiscussions(
                          props.discussionTopic.assignment.peerReviews?.dueAt
                        )}
                        revieweeName={assessmentRequest.user.name}
                        reviewLinkUrl={getReviewLinkUrl(
                          ENV.course_id,
                          props.discussionTopic.assignment._id,
                          assessmentRequest.user._id
                        )}
                        workflowState={assessmentRequest.workflowState}
                      />
                    )
                  )}
                </View>
              )}

              <Highlight isHighlighted={props.isHighlighted}>
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
                          discussionRoles={resolveAuthorRoles(
                            hasAuthor,
                            discussionTopicData.authorRoles
                          )}
                          editorName={showEditedBy ? discussionTopicData.editorName : null}
                          editedTimingDisplay={showEditedBy ? discussionTopicData.updatedAt : null}
                          attachmentDisplayName={discussionTopicData.attachmentDisplayName}
                          attachmentUrl={discussionTopicData.attachmentUrl}
                          postUtilities={
                            <PostToolbarContainer
                              canUnpublish={canUnpublish}
                              canCloseForComments={canCloseForComments}
                              deleteDiscussionTopic={deleteDiscussionTopic}
                              discussionTopicData={discussionTopicData}
                              requiresInitialPost={requiresInitialPost}
                              onPublish={onPublish}
                              onToggleLocked={onToggleLocked}
                              onMarkAllAsRead={onMarkAllAsRead}
                              onSubscribe={onSubscribe}
                              setSendToOpen={setSendToOpen}
                              setCopyToOpen={setCopyToOpen}
                            />
                          }
                        >
                          {discussionTopicData.attachmentDisplayName &&
                            discussionTopicData.attachmentUrl && (
                              <View as="div" padding="medium none none">
                                <Link href={discussionTopicData.attachmentUrl}>
                                  {discussionTopicData.attachmentDisplayName}
                                </Link>
                              </View>
                            )}
                          {canReply && (
                            <View as="div" padding="medium none none">
                              <Button
                                color="primary"
                                onClick={() => {
                                  setExpandedReply(!expandedReply)
                                }}
                                data-testid="discussion-topic-reply"
                              >
                                {I18n.t('Reply')}
                              </Button>
                            </View>
                          )}
                        </PostMessage>
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
                    {expandedReply && (
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
                    )}
                  </Flex.Item>
                </Flex>
              </Highlight>
            </View>
          </Flex.Item>
        </Flex>
      )}
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
  createDiscussionEntry: PropTypes.func,
  /**
   * useState Boolean to toggle highlight
   */
  isHighlighted: PropTypes.bool
}

export default DiscussionTopicContainer
