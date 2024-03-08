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

import {DiscussionDetails} from '../../components/DiscussionDetails/DiscussionDetails'
import DateHelper from '@canvas/datetime/dateHelper'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {getSpeedGraderUrl, getReviewLinkUrl, responsiveQuerySizes} from '../../utils'
import {Highlight} from '../../components/Highlight/Highlight'
import {useScope as useI18nScope} from '@canvas/i18n'
import {PeerReview} from '../../components/PeerReview/PeerReview'
import {DiscussionEntryContainer} from '../DiscussionEntryContainer/DiscussionEntryContainer'
import {
  DELETE_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_TOPIC,
  SUBSCRIBE_TO_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_READ_STATE,
} from '../../../graphql/Mutations'
import {LockedDiscussion} from '../../components/LockedDiscussion/LockedDiscussion'
import {PodcastFeed} from '../../components/PodcastFeed/PodcastFeed'
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {SearchContext} from '../../utils/constants'
import {useMutation, useApolloClient} from 'react-apollo'

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {DiscussionTopicAlertManager} from '../../components/DiscussionTopicAlertManager/DiscussionTopicAlertManager'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive/lib/Responsive'
import '@canvas/context-cards/react/StudentContextCardTrigger'

import assignmentRubricDialog from '../../../../discussion_topic/jquery/assignmentRubricDialog'
import rubricEditing from '../../../../../shared/rubrics/jquery/edit_rubric'

const I18n = useI18nScope('discussion_posts')

import('@canvas/rubrics/jquery/rubricEditBinding')

export const DiscussionTopicContainer = ({createDiscussionEntry, ...props}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)
  const [expandedReply, setExpandedReply] = useState(false)
  const [lastMarkAllAction, setLastMarkAllAction] = useState('')

  const {searchTerm, filter} = useContext(SearchContext)
  const isSearch = searchTerm || filter === 'unread'

  if (ENV.DISCUSSION?.GRADED_RUBRICS_URL) {
    assignmentRubricDialog.initTriggers()
  }

  const [deleteDiscussionTopic] = useMutation(DELETE_DISCUSSION_TOPIC, {
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion topic was successfully deleted.'))
      window.location.assign(`/courses/${ENV.course_id}/discussion_topics`)
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error deleting the discussion topic.'))
    },
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
    },
  })

  const client = useApolloClient()
  const resetDiscussionCache = () => {
    client.resetStore()
  }
  const [updateDiscussionReadState] = useMutation(UPDATE_DISCUSSION_READ_STATE, {
    update: resetDiscussionCache,
    onCompleted: data => {
      if (!data.updateDiscussionReadState.errors) {
        if (lastMarkAllAction === 'read') {
          setOnSuccess(I18n.t('You have successfully marked all as read.'))
        } else if (lastMarkAllAction === 'unread') {
          setOnSuccess(I18n.t('You have successfully marked all as unread.'))
        }
      } else if (lastMarkAllAction === 'read') {
        setOnFailure(I18n.t('There was an unexpected error marking all as read.'))
      } else if (lastMarkAllAction === 'unread') {
        setOnFailure(I18n.t('There was an unexpected error marking all as unread.'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error marking all as read.'))
    },
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
    },
  })

  const onDelete = () => {
    // eslint-disable-next-line no-alert
    if (window.confirm(I18n.t('Are you sure you want to delete this topic?'))) {
      deleteDiscussionTopic({
        variables: {
          id: props.discussionTopic._id,
        },
      })
    }
  }

  const onPublish = () => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        published: !props.discussionTopic.published,
      },
    })
  }

  const onToggleLocked = locked => {
    updateDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        locked,
      },
    })
  }

  const onMarkAllAsRead = () => {
    setLastMarkAllAction('read')
    updateDiscussionReadState({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        read: true,
      },
    })
  }

  const onMarkAllAsUnread = () => {
    setLastMarkAllAction('unread')
    updateDiscussionReadState({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        read: false,
      },
    })
  }

  const onSubscribe = () => {
    subscribeToDiscussionTopic({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        subscribed: !props.discussionTopic.subscribed,
      },
    })
  }

  const podcast_url =
    document.querySelector(`link[title='${I18n.t('Discussion Podcast Feed')}' ]`) ||
    document.querySelector("link[type='application/rss+xml']")

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          alert: {
            textSize: 'small',
          },
          discussionDetails: {
            margin: '0',
          },
          border: {
            width: '0 0 small 0',
            radius: 'none',
          },
          container: {
            padding: '0 xx-small',
          },
          replyButton: {
            display: 'block',
          },
          podcastButton: {
            display: 'block',
            padding: 'small none none none',
            textSize: 'small',
          },
          RCE: {
            paddingClosed: 'none',
            paddingOpen: 'none none small',
          },
        },
        desktop: {
          alert: {
            textSize: 'medium',
          },
          discussionDetails: {
            margin: '0 0 small 0',
          },
          border: {
            width: 'small',
            radius: 'medium',
          },
          container: {
            padding: '0 medium',
          },
          replyButton: {
            display: 'inline-block',
          },
          podcastButton: {
            display: 'inline-block',
            padding: 'none none none small',
            textSize: 'medium',
          },
          RCE: {
            paddingClosed: 'none medium none xx-large',
            paddingOpen: 'none medium medium xx-large',
          },
        },
      }}
      render={responsiveProps => (
        <>
          <DiscussionTopicAlertManager discussionTopic={props.discussionTopic} />
          {!isSearch && (
            <Highlight isHighlighted={props.isHighlighted} data-testid="highlight-container">
              <Flex as="div" direction="column" data-testid="discussion-topic-container">
                <Flex.Item>
                  <View
                    as="div"
                    borderWidth={responsiveProps?.border?.width}
                    borderRadius={responsiveProps?.border?.radius}
                    borderStyle="solid"
                    borderColor="primary"
                    padding="xx-small 0 small"
                    margin="0 0 small 0"
                  >
                    {!props.discussionTopic.availableForUser ? (
                      <LockedDiscussion title={props.discussionTopic.title} />
                    ) : (
                      <Flex direction="column" padding={responsiveProps?.container?.padding}>
                        <Flex.Item
                          shouldShrink={true}
                          shouldGrow={true}
                          margin={responsiveProps?.discussionDetails?.margin}
                        >
                          <DiscussionDetails
                            discussionTopic={props.discussionTopic}
                            inPacedCourse={ENV.IN_PACED_COURSE}
                            courseId={ENV.course_id}
                          />
                          {props.discussionTopic.assignment?.assessmentRequestsForCurrentUser?.map(
                            assessmentRequest => (
                              <PeerReview
                                key={assessmentRequest._id}
                                dueAtDisplayText={
                                  props.discussionTopic.assignment.peerReviews?.dueAt
                                }
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
                        </Flex.Item>
                        <Flex.Item shouldShrink={true} shouldGrow={true}>
                          <DiscussionEntryContainer
                            isTopic={true}
                            postUtilities={
                              <PostToolbar
                                onReadAll={
                                  !props.discussionTopic.initialPostRequiredForCurrentUser
                                    ? onMarkAllAsRead
                                    : null
                                }
                                onUnreadAll={
                                  !props.discussionTopic.initialPostRequiredForCurrentUser
                                    ? onMarkAllAsUnread
                                    : null
                                }
                                onDelete={
                                  props.discussionTopic.permissions.delete ? onDelete : null
                                }
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
                                    ? () => window.location.assign(ENV.EDIT_URL)
                                    : null
                                }
                                onTogglePublish={
                                  props.discussionTopic.permissions?.moderateForum
                                    ? onPublish
                                    : null
                                }
                                onToggleSubscription={onSubscribe}
                                onOpenSpeedgrader={
                                  props.discussionTopic.permissions?.speedGrader
                                    ? () => window.open(getSpeedGraderUrl(), '_blank')
                                    : null
                                }
                                onPeerReviews={
                                  props.discussionTopic.permissions?.peerReview
                                    ? () => window.location.assign(ENV.PEER_REVIEWS_URL)
                                    : null
                                }
                                showRubric={props.discussionTopic.permissions?.showRubric}
                                addRubric={props.discussionTopic.permissions?.addRubric}
                                onDisplayRubric={
                                  props.discussionTopic.permissions?.showRubric ||
                                  props.discussionTopic.permissions?.addRubric
                                    ? () => {
                                        assignmentRubricDialog.initDialog()
                                        assignmentRubricDialog.openDialog()
                                        rubricEditing.init()
                                      }
                                    : null
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
                                canManageContent={
                                  props.discussionTopic.permissions?.manageContent ||
                                  props.discussionTopic.permissions?.manageCourseContentAdd ||
                                  props.discussionTopic.permissions?.manageCourseContentEdit ||
                                  props.discussionTopic.permissions?.manageCourseContentDelete
                                }
                                discussionTopicId={props.discussionTopic._id}
                                discussionTopic={props.discussionTopic}
                              />
                            }
                            author={props.discussionTopic.author}
                            anonymousAuthor={props.discussionTopic.anonymousAuthor}
                            title={props.discussionTopic.title}
                            message={props.discussionTopic.message}
                            isSplitView={false}
                            editor={props.discussionTopic.editor}
                            createdAt={props.discussionTopic.createdAt}
                            updatedAt={props.discussionTopic.updatedAt}
                            timingDisplay={DateHelper.formatDatetimeForDiscussions(
                              props.discussionTopic.createdAt
                            )}
                            editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                              props.discussionTopic.updatedAt
                            )}
                            isTopicAuthor={true}
                            attachment={props.discussionTopic.attachment}
                            discussionTopic={props.discussionTopic}
                          >
                            {props.discussionTopic.permissions?.reply && !expandedReply && (
                              <>
                                <View
                                  as="div"
                                  padding="0"
                                  display={responsiveProps?.replyButton?.display}
                                >
                                  <span className="discussion-topic-reply-button">
                                    <Button
                                      display={responsiveProps?.replyButton?.display}
                                      color="primary"
                                      onClick={() => {
                                        setExpandedReply(!expandedReply)
                                      }}
                                      data-testid="discussion-topic-reply"
                                    >
                                      <Text weight="bold" size={responsiveProps.textSize}>
                                        {I18n.t('Reply')}
                                      </Text>
                                    </Button>
                                  </span>
                                </View>
                                {podcast_url?.href && (
                                  <View
                                    as="div"
                                    padding={responsiveProps?.podcastButton?.padding}
                                    display={responsiveProps?.replyButton?.display}
                                  >
                                    <PodcastFeed
                                      linkUrl={podcast_url.href}
                                      responsiveProps={responsiveProps.podcastButton}
                                    />
                                  </View>
                                )}
                              </>
                            )}
                          </DiscussionEntryContainer>
                        </Flex.Item>
                        <Flex.Item
                          shouldShrink={true}
                          shouldGrow={true}
                          padding={
                            expandedReply
                              ? responsiveProps?.RCE?.paddingOpen
                              : responsiveProps?.RCE?.paddingClosed
                          }
                          overflowX="hidden"
                          overflowY="hidden"
                        >
                          {expandedReply && (
                            <DiscussionEdit
                              rceIdentifier="root"
                              discussionAnonymousState={props.discussionTopic.anonymousState}
                              canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
                              show={expandedReply}
                              onSubmit={(message, _quotedEntryId, file, anonymousAuthorState) => {
                                if (createDiscussionEntry) {
                                  createDiscussionEntry(message, file, anonymousAuthorState)
                                  setExpandedReply(false)
                                }
                              }}
                              onCancel={() => {
                                setExpandedReply(false)
                                setTimeout(() => {
                                  document
                                    .querySelector('.discussion-topic-reply-button button')
                                    ?.focus()
                                }, 0)
                              }}
                              isAnnouncement={props.discussionTopic.isAnnouncement}
                            />
                          )}
                        </Flex.Item>
                      </Flex>
                    )}
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
          {props.discussionTopic.permissions?.addRubric && (
            /*
              HACK! this is here because edit_rubric.js expects there to be a #add_rubric_url on the page and sets it's <form action="..."> to it
            */
            // eslint-disable-next-line jsx-a11y/control-has-associated-label, jsx-a11y/anchor-has-content
            <a
              href={ENV.DISCUSSION?.CONTEXT_RUBRICS_URL}
              id="add_rubric_url"
              data-testid="add_rubric_url"
              style={{display: 'none'}}
            />
          )}
        </>
      )}
    />
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
  isHighlighted: PropTypes.bool,
}

export default DiscussionTopicContainer
