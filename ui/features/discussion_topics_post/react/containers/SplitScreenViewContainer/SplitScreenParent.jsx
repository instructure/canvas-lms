/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {Alert} from '@instructure/ui-alerts'
import {BackButton} from '../../components/BackButton/BackButton'
import DateHelper from '@canvas/datetime/dateHelper'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getDisplayName, isTopicAuthor, responsiveQuerySizes} from '../../utils'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {DiscussionEntryContainer} from '../DiscussionEntryContainer/DiscussionEntryContainer'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ReplyInfo} from '../../components/ReplyInfo/ReplyInfo'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {
  UPDATE_SPLIT_SCREEN_VIEW_DEEPLY_NESTED_ALERT,
  UPDATE_DISCUSSION_THREAD_READ_STATE,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
} from '../../../graphql/Mutations'
import {useMutation, useApolloClient} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {ReportReply} from '../../components/ReportReply/ReportReply'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = useI18nScope('discussion_posts')

export const SplitScreenParent = props => {
  const [updateSplitScreenViewDeeplyNestedAlert] = useMutation(
    UPDATE_SPLIT_SCREEN_VIEW_DEEPLY_NESTED_ALERT
  )

  const client = useApolloClient()
  const resetDiscussionCache = () => {
    client.resetStore()
  }

  const [updateDiscussionThreadReadState] = useMutation(UPDATE_DISCUSSION_THREAD_READ_STATE, {
    update: resetDiscussionCache,
  })

  const {setOnSuccess} = useContext(AlertManagerContext)
  const {setReplyFromId} = useContext(DiscussionManagerUtilityContext)
  const [isEditing, setIsEditing] = useState(false)
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportModalIsLoading, setReportModalIsLoading] = useState(false)
  const [reportingError, setReportingError] = useState(false)
  const threadActions = []

  const [updateDiscussionEntryReported] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      setReportModalIsLoading(false)
      setShowReportModal(false)
      setOnSuccess(I18n.t('You have reported this reply.'), false)
    },
    onError: () => {
      setReportModalIsLoading(false)
      setReportingError(true)
      setTimeout(() => {
        setReportingError(false)
      }, 3000)
    },
  })

  if (props?.discussionEntry?.permissions?.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        authorName={getDisplayName(props.discussionEntry)}
        delimiterKey={`reply-delimiter-${props.discussionEntry._id}`}
        onClick={() => props.setRCEOpen(true)}
        isReadOnly={props.RCEOpen}
        replyButtonRef={props.replyButtonRef}
      />
    )
  }

  if (
    props.discussionEntry.permissions.viewRating &&
    (props.discussionEntry.permissions.rate || props.discussionEntry.ratingSum > 0)
  ) {
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${props.discussionEntry.id}`}
        delimiterKey={`like-delimiter-${props.discussionEntry.id}`}
        onClick={() => {
          if (props.onToggleRating) {
            props.onToggleRating()
          }
        }}
        authorName={getDisplayName(props.discussionEntry)}
        isLiked={!!props.discussionEntry.entryParticipant?.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
        interaction={props.discussionEntry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (props.discussionEntry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.discussionEntry.id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry.id}`}
        expandText={
          <ReplyInfo
            replyCount={props.discussionEntry.rootEntryParticipantCounts?.repliesCount}
            unreadCount={props.discussionEntry.rootEntryParticipantCounts?.unreadCount}
          />
        }
        isReadOnly={!props.RCEOpen}
        isExpanded={false}
        onClick={() => props.setRCEOpen(false)}
        authorName={getDisplayName(props.discussionEntry)}
      />
    )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          textSize: 'small',
          padding: 'x-small',
        },
        desktop: {
          textSize: 'medium',
          padding: 'x-small medium',
        },
      }}
      render={responsiveProps => (
        <>
          {props.discussionEntry.parentId && (
            <View as="div" padding="small none none small">
              <BackButton
                onClick={() => props.onOpenSplitScreenView(props.discussionEntry.parentId, false)}
              />
            </View>
          )}
          {props.discussionEntry.depth > 2 &&
            props.RCEOpen &&
            ENV.should_show_deeply_nested_alert && (
              <Alert
                variant="warning"
                renderCloseButtonLabel="Close"
                margin="small"
                onDismiss={() => {
                  updateSplitScreenViewDeeplyNestedAlert({
                    variables: {
                      splitScreenViewDeeplyNestedAlert: false,
                    },
                  })

                  ENV.should_show_deeply_nested_alert = false
                }}
              >
                <Text size={responsiveProps.textSize}>
                  {props.discussionEntry.depth > 3
                    ? I18n.t(
                        'Deeply nested replies are no longer supported. Your reply will appear on the first page of this thread.'
                      )
                    : I18n.t(
                        'Deeply nested replies are no longer supported. Your reply will appear on on the page you are currently on.'
                      )}
                </Text>
              </Alert>
            )}
          <View as="div" padding={responsiveProps.padding}>
            <Highlight isHighlighted={props.isHighlighted}>
              <Flex padding="small">
                <Flex.Item shouldShrink={true} shouldGrow={true}>
                  <DiscussionEntryContainer
                    discussionTopic={props.discussionTopic}
                    discussionEntry={props.discussionEntry}
                    isTopic={false}
                    threadParent={true}
                    postUtilities={
                      <ThreadActions
                        authorName={getDisplayName(props.discussionEntry)}
                        id={props.discussionEntry.id}
                        isUnread={!props.discussionEntry.entryParticipant?.read}
                        onToggleUnread={props.onToggleUnread}
                        onDelete={props.discussionEntry.permissions?.delete ? props.onDelete : null}
                        onEdit={
                          props.discussionEntry.permissions?.update
                            ? () => {
                                setIsEditing(true)
                              }
                            : null
                        }
                        goToTopic={props.goToTopic}
                        onOpenInSpeedGrader={
                          props.discussionTopic.permissions?.speedGrader
                            ? props.onOpenInSpeedGrader
                            : null
                        }
                        onMarkThreadAsRead={readState =>
                          updateDiscussionThreadReadState({
                            variables: {
                              discussionEntryId: props.discussionEntry.rootEntryId
                                ? props.discussionEntry.rootEntryId
                                : props.discussionEntry.id,
                              read: readState,
                            },
                          })
                        }
                        onQuoteReply={
                          props?.discussionEntry?.permissions?.reply
                            ? () => {
                                setReplyFromId(props.discussionEntry._id)
                                props.setRCEOpen(true)
                              }
                            : null
                        }
                        onReport={
                          props.discussionTopic.permissions?.studentReporting
                            ? () => {
                                setShowReportModal(true)
                              }
                            : null
                        }
                        isReported={props.discussionEntry?.entryParticipant?.reportType != null}
                        moreOptionsButtonRef={props.moreOptionsButtonRef}
                      />
                    }
                    author={props.discussionEntry.author}
                    anonymousAuthor={props.discussionEntry.anonymousAuthor}
                    message={props.discussionEntry.message}
                    isEditing={isEditing}
                    onSave={(message, _quotedEntryId, file) => {
                      if (props.onSave) {
                        props.onSave(props.discussionEntry, message, file)
                        setIsEditing(false)
                      }
                    }}
                    onCancel={() => {
                      setIsEditing(false)
                      setTimeout(() => {
                        props.moreOptionsButtonRef?.current?.focus()
                      }, 0)
                    }}
                    isSplitView={true}
                    editor={props.discussionEntry.editor}
                    isUnread={!props.discussionEntry.entryParticipant?.read}
                    isForcedRead={props.discussionEntry.entryParticipant?.forcedReadState}
                    createdAt={props.discussionEntry.createdAt}
                    updatedAt={props.discussionEntry.updatedAt}
                    timingDisplay={DateHelper.formatDatetimeForDiscussions(
                      props.discussionEntry.createdAt
                    )}
                    editedTimingDisplay={DateHelper.formatDatetimeForDiscussions(
                      props.discussionEntry.updatedAt
                    )}
                    lastReplyAtDisplay={DateHelper.formatDatetimeForDiscussions(
                      props.discussionEntry.lastReply?.createdAt
                    )}
                    deleted={props.discussionEntry.deleted}
                    isTopicAuthor={isTopicAuthor(
                      props.discussionTopic.author,
                      props.discussionEntry.author
                    )}
                    quotedEntry={props.discussionEntry.quotedEntry}
                    attachment={props.discussionEntry.attachment}
                  >
                    {threadActions.length > 0 && (
                      <View as="div" padding="0">
                        <ThreadingToolbar
                          discussionEntry={props.discussionEntry}
                          isSplitView={true}
                        >
                          {threadActions}
                        </ThreadingToolbar>
                      </View>
                    )}
                  </DiscussionEntryContainer>
                  <ReportReply
                    onCloseReportModal={() => {
                      setShowReportModal(false)
                    }}
                    onSubmit={reportType => {
                      updateDiscussionEntryReported({
                        variables: {
                          discussionEntryId: props.discussionEntry._id,
                          reportType,
                        },
                      })
                      setReportModalIsLoading(true)
                    }}
                    showReportModal={showReportModal}
                    isLoading={reportModalIsLoading}
                    errorSubmitting={reportingError}
                  />
                </Flex.Item>
              </Flex>
              {props.children}
            </Highlight>
          </View>
        </>
      )}
    />
  )
}

SplitScreenParent.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onToggleRating: PropTypes.func,
  onSave: PropTypes.func,
  children: PropTypes.node,
  onOpenSplitScreenView: PropTypes.func,
  RCEOpen: PropTypes.bool,
  setRCEOpen: PropTypes.func,
  isHighlighted: PropTypes.bool,
  goToTopic: PropTypes.func,
  replyButtonRef: PropTypes.any,
  moreOptionsButtonRef: PropTypes.any,
}
