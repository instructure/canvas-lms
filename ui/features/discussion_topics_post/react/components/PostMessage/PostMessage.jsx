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

import {DiscussionEdit} from '../DiscussionEdit/DiscussionEdit'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useContext, useEffect} from 'react'
import {getDisplayName, responsiveQuerySizes} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {TranslationLoader} from './Translation/TranslationLoader'
import {Translation} from './Translation/Translation'

const I18n = createI18nScope('discussion_posts')

export function PostMessage({...props}) {
  const {searchTerm} = useContext(SearchContext)

  useEffect(() => {
    if (ENV.SEQUENCE !== undefined && props.isTopic) {
      import('@canvas/modules/jquery/prerequisites_lookup').then(() => {
        INST.lookupPrerequisites()
      })
    }
  }, [props.isTopic])

  let heading = 'h2'

  if (props.discussionEntry) {
    const depth = Math.min((props.discussionEntry.depth || 0) + 2, 5)
    heading = 'h' + depth.toString()
  }

  const id = props.discussionEntry?.id || 'topic'

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          titleMargin: 'small 0',
          titleDisplay: 'block',
          titleTextSize: 'large',
          titleTextWeight: 'bold',
          messageLeftPadding: undefined,
          isMobile: true,
        },
        desktop: {
          titleMargin: '0',
          titleDisplay: 'inline',
          titleTextSize: props.threadMode ? 'medium' : 'x-large',
          titleTextWeight: props.threadMode ? 'bold' : 'normal',
          messageLeftPadding:
            props.discussionEntry && props.discussionEntry.depth === 1 && !props.threadMode
              ? theme.spacing.xxSmall
              : undefined,
          isMobile: false,
        },
      }}
      render={responsiveProps => (
        <View>
          {props.title ? (
            <View margin={responsiveProps.titleMargin} display={responsiveProps.titleDisplay}>
              <Heading level="h2" size={responsiveProps.titleTextSize} data-testid="message_title">
                <AccessibleContent alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}>
                  {props.title}
                </AccessibleContent>
              </Heading>
            </View>
          ) : (
            <View as={heading} margin={responsiveProps.titleMargin}>
              <Text size={responsiveProps.titleTextSize} weight={responsiveProps.titleTextWeight}>
                <AccessibleContent
                  alt={I18n.t('Reply from %{author}', {
                    author: getDisplayName(props.discussionEntry),
                  })}
                />
              </Text>
            </View>
          )}

          <TranslationLoader id={id} />

          {props.isEditing ? (
            <View display="inline-block" margin="small none none none" width="100%">
              <DiscussionEdit
                rceIdentifier={`${props.discussionEntry._id}-edit`}
                discussionAnonymousState={props.discussionAnonymousState}
                canReplyAnonymously={props.canReplyAnonymously}
                onCancel={props.onCancel}
                value={props.message}
                attachment={props.attachment}
                quotedEntry={props.discussionEntry.quotedEntry}
                onSubmit={props.onSave}
                isEdit={true}
                isAnnouncement={props.discussionTopic?.isAnnouncement}
              />
            </View>
          ) : (
            <>
              <div
                className={'userMessage' + (responsiveProps.isMobile ? ' mobile' : '')}
                style={{
                  marginLeft: responsiveProps.messageLeftPadding,
                }}
              >
                <SearchSpan
                  isSplitView={props.isSplitView}
                  searchTerm={searchTerm}
                  text={props.message}
                  isAnnouncement={props.discussionTopic?.isAnnouncement}
                  isTopic={props.isTopic}
                  resourceId={
                    props.isTopic ? props.discussionTopic?._id : props.discussionEntry?._id
                  }
                />
                <Translation id={id} title={props.title} message={props.message}>
                  <Translation.Divider />
                  <Translation.Content>
                    {({title, message, targetLanguage}) => (
                      <>
                        {title && (
                          <Text
                            size={responsiveProps.titleTextSize}
                            data-testid="message_title_translated"
                            weight="bold"
                          >
                            <AccessibleContent alt={title} data-testid="post-title-translated">
                              <span lang={targetLanguage}>{title}</span>
                            </AccessibleContent>
                          </Text>
                        )}
                        {message && (
                          <SearchSpan
                            lang={targetLanguage}
                            isSplitView={props.isSplitView}
                            searchTerm={searchTerm}
                            text={message}
                            isAnnouncement={props.discussionTopic?.isAnnouncement}
                            isTopic={props.isTopic}
                            resourceId={
                              props.isTopic
                                ? props.discussionTopic?._id
                                : props.discussionEntry?._id
                            }
                            testId="post-message-translated"
                          />
                        )}
                      </>
                    )}
                  </Translation.Content>
                  <Translation.Error />
                </Translation>
              </div>
              <View data-testid="post-message-container" display="block">
                {props.children}
              </View>
            </>
          )}
        </View>
      )}
    />
  )
}

PostMessage.propTypes = {
  /**
   * Object containing the discussion entry information
   */
  discussionEntry: PropTypes.object,
  /**
   * Children to be directly rendered below the PostMessage
   */
  children: PropTypes.node,
  /**
   * Display text for the post's title. Only pass this in if it's a DiscussionTopic
   */
  title: PropTypes.string,
  /**
   * Display text for the post's message
   */
  message: PropTypes.string,
  /*
   * Display attachment for the post's message
   */
  attachment: PropTypes.object,
  /**
   * Determines if the editor should be displayed
   */
  isEditing: PropTypes.bool,
  /**
   * Callback for when Editor Save button is pressed
   */
  onSave: PropTypes.func,
  /**
   * Callback for when Editor Cancel button is pressed
   */
  onCancel: PropTypes.func,
  isSplitView: PropTypes.bool,
  discussionAnonymousState: PropTypes.string,
  canReplyAnonymously: PropTypes.bool,
  threadMode: PropTypes.bool,
  isTopic: PropTypes.bool,
  discussionTopic: PropTypes.object,
}

PostMessage.defaultProps = {
  isSplitView: false,
}

export default PostMessage
