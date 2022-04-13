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
import {responsiveQuerySizes} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'
import {User} from '../../../graphql/User'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export function PostMessage({...props}) {
  const {searchTerm} = useContext(SearchContext)

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          titleMargin: '0',
          titleTextSize: 'medium',
          titleTextWeight: 'bold',
          messageTextSize: 'fontSizeSmall'
        },
        desktop: {
          titleMargin: '0 0 small 0',
          titleTextSize: 'x-large',
          titleTextWeight: 'normal',
          messageTextSize: 'fontSizeMedium'
        }
      }}
      render={responsiveProps => (
        <View>
          {props.title && (
            <View as="h1" margin={responsiveProps.titleMargin}>
              <Text size={responsiveProps.titleTextSize} weight={responsiveProps.titleTextWeight}>
                <AccessibleContent alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}>
                  {props.title}
                </AccessibleContent>
              </Text>
            </View>
          )}
          {props.isEditing ? (
            <View display="inline-block" margin="small none none none" width="100%">
              <DiscussionEdit
                discussionAnonymousState={props.discussionAnonymousState}
                canReplyAnonymously={props.canReplyAnonymously}
                onCancel={props.onCancel}
                value={props.draftMessage || props.message}
                attachment={props.attachment}
                onSubmit={props.onSave}
                isEdit
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
                  fontSize: theme.variables.typography[responsiveProps.messageTextSize]
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
   * Object containing the author information
   */
  author: User.shape,
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
  draftSaved: PropTypes.bool
}

PostMessage.defaultProps = {
  isIsolatedView: false
}

export default PostMessage
