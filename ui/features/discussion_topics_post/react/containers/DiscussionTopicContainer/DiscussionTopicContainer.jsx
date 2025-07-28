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

import {useApolloClient, useMutation} from '@apollo/client'
import DateHelper from '@canvas/datetime/dateHelper'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useContext, useState, useCallback} from 'react'
import {Discussion} from '../../../graphql/Discussion'
import {
  DELETE_DISCUSSION_TOPIC,
  SUBSCRIBE_TO_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_READ_STATE,
  UPDATE_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_TOPIC_PARTICIPANT,
} from '../../../graphql/Mutations'
import {DiscussionDetails} from '../../components/DiscussionDetails/DiscussionDetails'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {DiscussionSummary} from '../../components/DiscussionSummary/DiscussionSummary'
import {Highlight} from '../../components/Highlight/Highlight'
import {LockedDiscussion} from '../../components/LockedDiscussion/LockedDiscussion'
import {PeerReview} from '../../components/PeerReview/PeerReview'
import {PodcastFeed} from '../../components/PodcastFeed/PodcastFeed'
import {PostToolbar} from '../../components/PostToolbar/PostToolbar'
import {getReviewLinkUrl, getSpeedGraderUrl, responsiveQuerySizes} from '../../utils'
import {SearchContext, isSpeedGraderInTopUrl} from '../../utils/constants'
import {DiscussionEntryContainer} from '../DiscussionEntryContainer/DiscussionEntryContainer'

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive/lib/Responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {DiscussionTopicAlertManager} from '../../components/DiscussionTopicAlertManager/DiscussionTopicAlertManager'
import '@canvas/context-cards/react/StudentContextCardTrigger'

import assignmentRubricDialog from '@canvas/discussions/jquery/assignmentRubricDialog'
import TopNavPortalWithDefaults, {
  addCrumbs,
} from '@canvas/top-navigation/react/TopNavPortalWithDefaults'
import {assignLocation, openWindow} from '@canvas/util/globalUtils'
import rubricEditing from '../../../../../shared/rubrics/jquery/edit_rubric'
import {useEventHandler, KeyboardShortcuts} from '../../KeyboardShortcuts/useKeyboardShortcut'
import {SummarizeButton} from './SummarizeButton'
import {DiscussionInsightsButton} from './DiscussionInsightsButton'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('discussion_posts')

import('@canvas/rubrics/jquery/rubricEditBinding')

export const DiscussionTopicContainer = ({
  createDiscussionEntry,
  setExpandedTopicReply,
  expandedTopicReply,
  ...props
}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendToOpen, setSendToOpen] = useState(false)
  const [copyToOpen, setCopyToOpen] = useState(false)
  const [lastMarkAllAction, setLastMarkAllAction] = useState('')
  const [summary, setSummary] = useState(null)
  const [isFeedbackLoading, setIsFeedbackLoading] = useState(false)
  const [liked, setLiked] = useState(false)
  const [disliked, setDisliked] = useState(false)
  const [isSummaryEnabled, setIsSummaryEnabled] = useState(ENV.discussion_summary_enabled || false)
  const [updateDiscussionTopicParticipant] = useMutation(UPDATE_DISCUSSION_TOPIC_PARTICIPANT)

  const {searchTerm, filter} = useContext(SearchContext)
  const isSearch = searchTerm || filter === 'unread'

  const contextType = ENV.context_type?.toLowerCase()
  const contextId = ENV.context_id
  const apiUrlPrefix = `/api/v1/${contextType}s/${contextId}/discussion_topics/${ENV.discussion_topic_id}`

  if (ENV.DISCUSSION?.GRADED_RUBRICS_URL) {
    assignmentRubricDialog.initTriggers()
  }

  const isAnnouncement = props.discussionTopic.isAnnouncement

  const [deleteDiscussionTopic] = useMutation(DELETE_DISCUSSION_TOPIC, {
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion topic was successfully deleted.'))
      assignLocation(
        `/courses/${ENV.course_id}/${isAnnouncement ? 'announcements' : 'discussion_topics'}`,
      )
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

  const handleSummaryEnabled = async summaryEnabled => {
    return updateDiscussionTopicParticipant({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        summaryEnabled: summaryEnabled,
      },
    }).then(() => {
      setIsSummaryEnabled(summaryEnabled)
    })
  }

  const userHasEntry = () => {
    return props.discussionTopic.discussionEntriesConnection.nodes.some(entry => {
      return entry.author?._id === ENV.current_user_id
    })
  }

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
            : I18n.t('You have successfully unsubscribed from the discussion topic.'),
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
    const message = isAnnouncement
      ? I18n.t('Are you sure you want to delete this announcement?')
      : I18n.t('Are you sure you want to delete this topic?')

    if (window.confirm(message)) {
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

  const onCancelTopicReply = () => {
    setExpandedTopicReply(false)
    setTimeout(() => {
      document.querySelector('.discussion-topic-reply-button button')?.focus()
    }, 0)
  }

  const onOpenTopicReply = () => {
    setExpandedTopicReply(true)
  }

  useEventHandler(KeyboardShortcuts.ON_OPEN_TOPIC_REPLY, onOpenTopicReply)

  const handleSummarizeClick = async () => {
    if (props.isSummaryEnabled) {
      props.setIsSummaryEnabled(false)
    } else {
      if (summary) {
        await postDiscussionSummaryFeedback('disable_summary')
      }

      try {
        await doFetchApi({
          method: 'PUT',
          path: `${apiUrlPrefix}/summaries/disable`,
        })
      } catch (_error) {
        setOnFailure(
          I18n.t('There was an unexpected error while disabling the discussion summary.'),
        )
        return
      }
      props.setIsSummaryEnabled(true)
    }
  }

  const postDiscussionSummaryFeedback = useCallback(
    async action => {
      setIsFeedbackLoading(true)

      try {
        const {json} = await doFetchApi({
          method: 'POST',
          path: `${apiUrlPrefix}/summaries/${summary.id}/feedback`,
          body: {
            _action: action,
          },
        })
        setLiked(json.liked)
        setDisliked(json.disliked)
      } catch (error) {
        setOnFailure(
          I18n.t('There was an unexpected error while submitting the discussion summary feedback.'),
        )
      }

      setIsFeedbackLoading(false)
    },
    [apiUrlPrefix, summary, setOnFailure],
  )

  const handleDisableSummaryClick = async () => {
    if (summary) {
      await postDiscussionSummaryFeedback('disable_summary')
    }

    await handleSummaryEnabled(false)
  }

  const podcast_url =
    document.querySelector(`link[title='${I18n.t('Discussion Podcast Feed')}' ]`) ||
    document.querySelector("link[type='application/rss+xml']")

  const handleBreadCrumbSetter = ({getCrumbs, setCrumbs}) => {
    const discussionOrAnnouncement = isAnnouncement
      ? I18n.t('Announcements')
      : I18n.t('Discussions')
    const discussionOrAnnouncementUrl = isAnnouncement ? 'announcements' : 'discussion_topics'
    const crumbs = getCrumbs()
    setCrumbs(
      addCrumbs([
        {name: discussionOrAnnouncement, url: `${crumbs[0].url}/${discussionOrAnnouncementUrl}`},
        {name: props.discussionTopic.title || '', url: ''},
      ]),
    )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          direction: 'column',
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
            padding: '0',
          },
          replyButton: {
            display: 'block',
          },
          summaryButton: {
            shouldGrow: true,
            shouldShrink: true,
          },
          RCE: {
            paddingClosed: 'none',
            paddingOpen: 'none none small',
          },
        },
        desktop: {
          direction: 'row',
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
          summaryButton: {
            shouldGrow: false,
            shouldShrink: false,
          },
          RCE: {
            paddingClosed: 'none medium none xx-large',
            paddingOpen: 'none medium medium xx-large',
          },
        },
      }}
      render={(responsiveProps, matches) => (
        <>
          <TopNavPortalWithDefaults
            getBreadCrumbSetter={handleBreadCrumbSetter}
            useStudentView={true}
          />
          <DiscussionTopicAlertManager
            discussionTopic={props.discussionTopic}
            userHasEntry={userHasEntry()}
          />
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
                    padding={matches.includes('mobile') ? 'small 0 medium 0' : 'small'}
                    margin={matches.includes('mobile') ? '0 0 medium 0' : '0 0 small 0'}
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
                            replyToTopicSubmission={props.replyToTopicSubmission}
                            replyToEntrySubmission={props.replyToEntrySubmission}
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
                                  assessmentRequest.user._id,
                                )}
                                workflowState={assessmentRequest.workflowState}
                                disabled={!userHasEntry()}
                              />
                            ),
                          )}
                        </Flex.Item>
                        <Flex.Item shouldShrink={true} shouldGrow={true} overflowY="visible">
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
                                    ? () => assignLocation(ENV.EDIT_URL)
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
                                    ? () => openWindow(getSpeedGraderUrl(), '_blank')
                                    : null
                                }
                                onPeerReviews={
                                  props.discussionTopic.permissions?.peerReview
                                    ? () => assignLocation(ENV.PEER_REVIEWS_URL)
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
                            editedAt={props.discussionTopic.editedAt}
                            delayedPostAt={props.discussionTopic.delayedPostAt}
                            timingDisplay={DateHelper.formatDatetimeForDiscussions(
                              props.discussionTopic.createdAt,
                            )}
                            editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                              props.discussionTopic.editedAt,
                            )}
                            isTopicAuthor={true}
                            attachment={props.discussionTopic.attachment}
                            discussionTopic={props.discussionTopic}
                          >
                            {!props.discussionTopic.permissions?.reply && (
                              <Text
                                size="small"
                                color="secondary"
                                data-testid="discussion-topic-closed-for-comments"
                              >
                                {I18n.t('This topic is closed for comments.')}
                              </Text>
                            )}
                            {props.discussionTopic.permissions?.reply && !expandedTopicReply && (
                              <>
                                <Flex
                                  width="100%"
                                  direction={responsiveProps.direction}
                                  wrap="wrap"
                                  gap="small"
                                  margin="small 0 0 0"
                                >
                                  <Flex.Item overflowY="visible">
                                    <span className="discussion-topic-reply-button">
                                      <Button
                                        display={responsiveProps?.replyButton?.display}
                                        color="primary"
                                        onClick={onOpenTopicReply}
                                        data-testid="discussion-topic-reply"
                                      >
                                        <Text weight="bold" size={responsiveProps.textSize}>
                                          {I18n.t('Reply')}
                                        </Text>
                                      </Button>
                                    </span>
                                  </Flex.Item>
                                  {podcast_url?.href && (
                                    <Flex.Item overflowY="visible">
                                      <PodcastFeed
                                        linkUrl={podcast_url.href}
                                        isMobile={matches.includes('mobile')}
                                      />
                                    </Flex.Item>
                                  )}
                                  <Flex.Item shouldGrow>
                                    <Flex
                                      direction="row"
                                      wrap="wrap"
                                      gap="small"
                                      justifyItems="end"
                                    >
                                      {ENV.user_can_access_insights && (
                                        <Flex.Item overflowY="visible">
                                          <DiscussionInsightsButton
                                            isMobile={matches.includes('mobile')}
                                            onClick={() => {
                                              assignLocation(ENV.INSIGHTS_URL)
                                            }}
                                          />
                                        </Flex.Item>
                                      )}
                                      {ENV.user_can_summarize && !isSpeedGraderInTopUrl && (
                                        <Flex.Item
                                          shouldGrow={responsiveProps?.summaryButton?.shouldGrow}
                                          shouldShrink={
                                            responsiveProps?.summaryButton?.shouldShrink
                                          }
                                          overflowY="visible"
                                        >
                                          <SummarizeButton
                                            onClick={() => handleSummaryEnabled(!isSummaryEnabled)}
                                            isEnabled={isSummaryEnabled}
                                            isLoading={isFeedbackLoading}
                                            isMobile={matches.includes('mobile')}
                                          />
                                        </Flex.Item>
                                      )}
                                    </Flex>
                                  </Flex.Item>
                                </Flex>
                              </>
                            )}
                          </DiscussionEntryContainer>
                        </Flex.Item>
                        <Flex.Item
                          shouldShrink={true}
                          shouldGrow={true}
                          padding={
                            expandedTopicReply
                              ? responsiveProps?.RCE?.paddingOpen
                              : responsiveProps?.RCE?.paddingClosed
                          }
                          overflowX="hidden"
                          overflowY="hidden"
                        >
                          {expandedTopicReply && (
                            <DiscussionEdit
                              rceIdentifier="root"
                              discussionAnonymousState={props.discussionTopic.anonymousState}
                              canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
                              show={expandedTopicReply}
                              onSubmit={(message, _quotedEntryId, file, anonymousAuthorState) => {
                                if (createDiscussionEntry) {
                                  createDiscussionEntry(message, file, anonymousAuthorState)
                                }
                              }}
                              isSubmitting={props.isSubmitting}
                              onCancel={onCancelTopicReply}
                              isAnnouncement={isAnnouncement}
                            />
                          )}
                        </Flex.Item>
                      </Flex>
                    )}
                  </View>
                </Flex.Item>
                {ENV.user_can_summarize && isSummaryEnabled && (
                  <Flex.Item>
                    <View
                      as="div"
                      borderWidth={responsiveProps?.border?.width}
                      borderRadius={responsiveProps?.border?.radius}
                      borderStyle="solid"
                      borderColor="primary"
                      padding={matches.includes('mobile') ? '0' : 'small'}
                      margin="0 0 small 0"
                    >
                      <Flex direction="column" padding={responsiveProps?.container?.padding}>
                        <DiscussionSummary
                          onDisableSummaryClick={() => handleSummaryEnabled(false)}
                          isMobile={!!matches.includes('mobile')}
                          summary={summary}
                          onSetSummary={setSummary}
                          isFeedbackLoading={isFeedbackLoading}
                          onSetIsFeedbackLoading={setIsFeedbackLoading}
                          liked={liked}
                          onSetLiked={setLiked}
                          disliked={disliked}
                          onSetDisliked={setDisliked}
                          postDiscussionSummaryFeedback={postDiscussionSummaryFeedback}
                        />
                      </Flex>
                    </View>
                  </Flex.Item>
                )}
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
            // eslint-disable-next-line jsx-a11y/anchor-has-content
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
  /**
   * useState object to set the REPLY_TO_TOPIC submission status
   */
  replyToTopicSubmission: PropTypes.object,
  /**
   * useState object to set the REPLY_TO_ENTRY submission status
   */
  replyToEntrySubmission: PropTypes.object,
  expandedTopicReply: PropTypes.bool,
  setExpandedTopicReply: PropTypes.func,
  isSubmitting: PropTypes.bool,
}
