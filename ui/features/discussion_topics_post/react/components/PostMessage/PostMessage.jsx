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
import React, {useContext} from 'react'
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
          messageTextSize: 'fontSizeSmall',
        },
        desktop: {
          titleMargin: props.threadMode ? '0' : '0 0 small 0',
          titleTextSize: props.threadMode ? 'medium' : 'x-large',
          titleTextWeight: props.threadMode ? 'bold' : 'normal',
          messageTextSize: props.threadMode ? 'fontSizeSmall' : 'fontSizeMedium',
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
                value={props.draftMessage || props.message}
                attachment={props.attachment}
                onSubmit={props.onSave}
                isEdit={true}
                onSetDraftSaved={props.onSetDraftSaved}
                draftSaved={props.draftSaved}
                updateDraft={newDraftMessage => {
                  props.onCreateDiscussionEntryDraft(newDraftMessage)
                }}
              />
            </View>
          ) : (
            <>
              <span
                style={{
                  fontSize: theme.variables.typography[responsiveProps.messageTextSize],
                }}
              >
                <SearchSpan
                  isIsolatedView={props.isIsolatedView}
                  searchTerm={searchTerm}
                  text={props.message}
                />
              </span>
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
  isIsolatedView: PropTypes.bool,
  onCreateDiscussionEntryDraft: PropTypes.func,
  draftMessage: PropTypes.string,
  onSetDraftSaved: PropTypes.func,
  discussionAnonymousState: PropTypes.string,
  canReplyAnonymously: PropTypes.bool,
  draftSaved: PropTypes.bool,
  threadMode: PropTypes.bool,
  isTopic: PropTypes.bool,
}

PostMessage.defaultProps = {
  isIsolatedView: false,
}

export default PostMessage
