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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useContext, useEffect} from 'react'
import {getDisplayName, responsiveQuerySizes} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export function PostMessage({...props}) {
  const {searchTerm} = useContext(SearchContext)

  useEffect(() => {
    if (ENV.SEQUENCE !== undefined && props.isTopic) {
      // eslint-disable-next-line promise/catch-or-return
      import('@canvas/modules/jquery/prerequisites_lookup').then(() => {
        INST.lookupPrerequisites()
      })
    }
  }, [props.isTopic])

  let heading = 'h2'

  if (props.discussionEntry) {
    const depth = Math.min(props.discussionEntry.depth + 2, 5)
    heading = 'h' + depth.toString()
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          titleMargin: '0',
          titleTextSize: 'small',
          titleTextWeight: 'bold',
          messageTextSize: 'fontSizeXSmall',
          messageLeftPadding: undefined,
        },
        desktop: {
          titleMargin: props.threadMode ? '0' : '0 0 small 0',
          titleTextSize: props.threadMode ? 'medium' : 'x-large',
          titleTextWeight: props.threadMode ? 'bold' : 'normal',
          messageTextSize: props.threadMode ? 'fontSizeSmall' : 'fontSizeMedium',
          messageLeftPadding:
            props.discussionEntry && props.discussionEntry.depth === 1 && !props.threadMode
              ? theme.variables.spacing.xxSmall
              : undefined,
        },
      }}
      render={responsiveProps => (
        <View>
          {props.title ? (
            <View
              as={heading}
              margin={responsiveProps.titleMargin}
              padding={props.isTopic ? 'small 0 0 0' : '0'}
            >
              <Text size={responsiveProps.titleTextSize} weight={responsiveProps.titleTextWeight}>
                <AccessibleContent alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}>
                  {props.title}
                </AccessibleContent>
              </Text>
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
          {props.isEditing ? (
            <View display="inline-block" margin="small none none none" width="100%">
              <DiscussionEdit
                rceIdentifier={`${props.discussionEntry._id}-edit`}
                discussionAnonymousState={props.discussionAnonymousState}
                canReplyAnonymously={props.canReplyAnonymously}
                onCancel={props.onCancel}
                value={props.message}
                attachment={props.attachment}
                onSubmit={props.onSave}
                isEdit={true}
                isAnnouncement={props.discussionTopic?.isAnnouncement}
              />
            </View>
          ) : (
            <>
              <div
                style={{
                  marginLeft: responsiveProps.messageLeftPadding,
                  fontSize: theme.variables.typography[responsiveProps.messageTextSize],
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
              </div>
              <View display="block">{props.children}</View>
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
  message: PropTypes.string.isRequired,
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
