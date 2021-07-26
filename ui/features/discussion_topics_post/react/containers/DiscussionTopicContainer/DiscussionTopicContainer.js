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
import DateHelper from '../../../../../shared/datetime/dateHelper'
import DirectShareUserModal from '../../../../../shared/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '../../../../../shared/direct-sharing/react/components/DirectShareCourseTray'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {
  getSpeedGraderUrl,
  getEditUrl,
  getPeerReviewsUrl,
  isGraded,
  getReviewLinkUrl,
  resolveAuthorRoles
} from '../../utils'
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
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {SearchContext} from '../../utils/constants'
import {useMutation, useApolloClient} from 'react-apollo'

import {Alert as AlertFRD} from '@instructure/ui-alerts'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'

export const DiscussionTopicContainer = ({createDiscussionEntry, ...props}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)
  const [expandedReply, setExpandedReply] = useState(false)

  const {searchTerm} = useContext(SearchContext)

  let assignmentOverrides = props.discussionTopic?.assignment?.assignmentOverrides?.nodes || []
  let dueAt = ''

  const canSeeMultipleDueDates = !!(
    props.discussionTopic.permissions?.readAsAdmin && assignmentOverrides.length > 0
  )

  const defaultDateSet =
    !!props.discussionTopic.assignment?.dueAt ||
    !!props.discussionTopic.assignment?.lockAt ||
    !!props.discussionTopic.assignment?.unlockAt

  const singleOverrideWithNoDefault = !defaultDateSet && assignmentOverrides.length === 1

  if (isGraded(props.discussionTopic.assignment)) {
    if (assignmentOverrides.length > 0 && canSeeMultipleDueDates && defaultDateSet) {
      assignmentOverrides = assignmentOverrides.concat({
        dueAt: props.discussionTopic.assignment?.dueAt,
        unlockAt: props.discussionTopic.assignment?.unlockAt,
        lockAt: props.discussionTopic.assignment?.lockAt,
        title: I18n.t('Everyone Else'),
        id: props.discussionTopic.assignment?.id
      })
    }

    const showSingleOverrideDueDate = () => {
      return assignmentOverrides[0]?.dueAt
        ? I18n.t('%{title}: Due %{date}', {
            title: assignmentOverrides[0]?.title,
            date: DateHelper.formatDatetimeForDiscussions(assignmentOverrides[0]?.dueAt)
          })
        : I18n.t('%{title}: No Due Date', {
            title: assignmentOverrides[0]?.title
          })
    }

    const showDefaultDueDate = () => {
      return props.discussionTopic.assignment?.dueAt
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
      if (props.discussionTopic.permissions?.readAsAdmin)
        return singleOverrideWithNoDefault ? showSingleOverrideDueDate() : showDefaultDueDate()

      return showNonAdminDueDate()
    }

    dueAt = getDueDateText()
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

  const client = useApolloClient()
  const resetDiscussionCache = () => {
    client.resetStore()
  }
  const [updateDiscussionReadState] = useMutation(UPDATE_DISCUSSION_READ_STATE, {
    update: resetDiscussionCache,
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

  const onDelete = () => {
    // eslint-disable-next-line no-alert
    if (window.confirm(I18n.t('Are you sure you want to delete this topic'))) {
      deleteDiscussionTopic({
        variables: {
          id: props.discussionTopic._id
        }
      })
    }
  }

  const onPublish = () => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        published: !props.discussionTopic.published
      }
    })
  }

  const onToggleLocked = locked => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        locked
      }
    })
  }

  const onMarkAllAsRead = () => {
    updateDiscussionReadState({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        read: true
      }
    })
  }

  const onSubscribe = () => {
    subscribeToDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        subscribed: !props.discussionTopic.subscribed
      }
    })
  }

  return (
    <>
      {props.discussionTopic.initialPostRequiredForCurrentUser && (
        <AlertFRD renderCloseButtonLabel="Close">
          {I18n.t('You must post before seeing replies.')}
        </AlertFRD>
      )}
      {props.discussionTopic.permissions?.readAsAdmin &&
        props.discussionTopic.groupSet &&
        props.discussionTopic.assignment?.onlyVisibleToOverrides && (
          <View as="div" margin="none none small" width="80%" data-testid="differentiated-alert">
            <AlertFRD renderCloseButtonLabel="Close">
              {I18n.t(
                'Note: for differentiated group topics, some threads may not have any students assigned.'
              )}
            </AlertFRD>
          </View>
        )}
      {!searchTerm && (
        <Highlight isHighlighted={props.isHighlighted} data-testid="highlight-container">
          <Flex as="div" direction="column" data-testid="discussion-topic-container">
            <Flex.Item>
              <View
                as="div"
                borderWidth="small"
                borderRadius="medium"
                borderStyle="solid"
                borderColor="primary"
              >
                {isGraded(props.discussionTopic.assignment) && (
                  <View as="div" padding="none medium none">
                    <Alert
                      dueAtDisplayText={dueAt}
                      pointsPossible={props.discussionTopic.assignment.pointsPossible || 0}
                      assignmentOverrides={singleOverrideWithNoDefault ? [] : assignmentOverrides}
                      canSeeMultipleDueDates={canSeeMultipleDueDates}
                    />
                    {props.discussionTopic.assignment?.assessmentRequestsForCurrentUser?.map(
                      assessmentRequest => (
                        <PeerReview
                          key={assessmentRequest._id}
                          dueAtDisplayText={DateHelper.formatDatetimeForDiscussions(
                            props.discussionTopic.assignment.peerReviews?.dueAt
                          )}
                          revieweeName={assessmentRequest.user.displayName}
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

                <Flex direction="column">
                  <Flex.Item>
                    <Flex
                      direction="row"
                      justifyItems="space-between"
                      padding="medium small none"
                      alignItems="start"
                    >
                      <Flex.Item shouldShrink shouldGrow padding="0 0 medium 0">
                        <PostMessage
                          author={props.discussionTopic.author}
                          timingDisplay={DateHelper.formatDatetimeForDiscussions(
                            props.discussionTopic.postedAt
                          )}
                          title={props.discussionTopic.title}
                          message={props.discussionTopic.message}
                          discussionRoles={resolveAuthorRoles(
                            true,
                            props.discussionTopic.author?.courseRoles
                          )}
                          editor={props.discussionTopic.editor}
                          editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                            props.discussionTopic.updatedAt
                          )}
                          postUtilities={
                            <PostToolbar
                              onReadAll={
                                !props.discussionTopic.initialPostRequiredForCurrentUser
                                  ? onMarkAllAsRead
                                  : null
                              }
                              onDelete={props.discussionTopic.permissions.delete ? onDelete : null}
                              repliesCount={props.discussionTopic.entryCounts?.repliesCount}
                              unreadCount={props.discussionTopic.entryCounts?.unreadCount}
                              onSend={
                                props.discussionTopic.permissions?.copyAndSendTo
                                  ? () => setSendToOpen(true)
                                  : null
                              }
                              onCopy={
                                props.discussionTopic.permissions?.copyAndSendTo
                                  ? () => setCopyToOpen(true)
                                  : null
                              }
                              onEdit={
                                props.discussionTopic.permissions?.update
                                  ? () =>
                                      window.location.assign(
                                        getEditUrl(ENV.course_id, props.discussionTopic._id)
                                      )
                                  : null
                              }
                              onTogglePublish={
                                props.discussionTopic.permissions?.moderateForum ? onPublish : null
                              }
                              onToggleSubscription={onSubscribe}
                              onOpenSpeedgrader={
                                props.discussionTopic.permissions?.speedGrader
                                  ? () =>
                                      window.open(
                                        getSpeedGraderUrl(
                                          ENV.course_id,
                                          props.discussionTopic.assignment?._id
                                        ),
                                        '_blank'
                                      )
                                  : null
                              }
                              onPeerReviews={
                                props.discussionTopic.permissions?.peerReview
                                  ? () =>
                                      window.location.assign(
                                        getPeerReviewsUrl(
                                          ENV.course_id,
                                          props.discussionTopic.assignment?._id
                                        )
                                      )
                                  : null
                              }
                              onShowRubric={
                                props.discussionTopic.permissions?.showRubric ? () => {} : null
                              }
                              onAddRubric={
                                props.discussionTopic.permissions?.addRubric ? () => {} : null
                              }
                              isPublished={props.discussionTopic.published}
                              canUnpublish={props.discussionTopic.canUnpublish}
                              isSubscribed={props.discussionTopic.subscribed}
                              onOpenForComments={
                                props.discussionTopic.permissions?.openForComments
                                  ? () => onToggleLocked(false)
                                  : null
                              }
                              onCloseForComments={
                                props.discussionTopic.permissions?.closeForComments &&
                                !props.discussionTopic.rootTopic
                                  ? () => onToggleLocked(true)
                                  : null
                              }
                              onShareToCommons={
                                props.discussionTopic.permissions?.manageContent &&
                                ENV.discussion_topic_menu_tools?.length > 0
                                  ? () =>
                                      window.location.assign(
                                        `${ENV.discussion_topic_menu_tools[0].base_url}&discussion_topics%5B%5D=${props.discussionTopic._id}`
                                      )
                                  : null
                              }
                            />
                          }
                        >
                          {props.discussionTopic.attachment && (
                            <View as="div" padding="medium none none">
                              <Link href={props.discussionTopic.attachment.url}>
                                {props.discussionTopic.attachment.displayName}
                              </Link>
                            </View>
                          )}
                          {props.discussionTopic.permissions?.reply && (
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
              </View>
            </Flex.Item>
          </Flex>
        </Highlight>
      )}
      <DirectShareUserModal
        open={sendToOpen}
        courseId={ENV.course_id}
        contentShare={{content_type: 'discussion_topic', content_id: props.discussionTopic._id}}
        onDismiss={() => {
          setSendToOpen(false)
        }}
      />
      <DirectShareCourseTray
        open={copyToOpen}
        sourceCourseId={ENV.course_id}
        contentSelection={{discussion_topics: [props.discussionTopic._id]}}
        onDismiss={() => {
          setCopyToOpen(false)
        }}
      />
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
