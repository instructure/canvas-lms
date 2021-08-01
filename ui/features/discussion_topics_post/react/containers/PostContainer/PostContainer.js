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

import {AuthorInfo} from '../../components/AuthorInfo/AuthorInfo'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'
import {User} from '../../../graphql/User'

import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'

export const PostContainer = props => {
  if (props.deleted) {
    return (
      <DeletedPostMessage
        deleterName={props.editor ? props.editor.displayName : props.author.displayName}
        timingDisplay={props.timingDisplay}
        deletedTimingDisplay={props.editedTimingDisplay}
      >
        {props.children}
      </DeletedPostMessage>
    )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          direction: 'column-reverse',
          authorInfo: {
            padding: '0'
          },
          postUtilities: {
            align: 'stretch',
            margin: '0 0 small 0',
            padding: '0'
          },
          postMessage: {
            padding: '0',
            paddingNoAuthor: '0',
            margin: 'xx-small 0 0 0'
          }
        },
        desktop: {
          direction: 'row',
          authorInfo: {
            padding: 'xx-small 0 0 0'
          },
          postUtilities: {
            align: 'start',
            margin: '0',
            padding: 'xx-small'
          },
          postMessage: {
            padding: 'x-small 0 small xx-large',
            paddingNoAuthor: '0 0 xx-small xx-small',
            margin: '0'
          }
        }
      }}
      render={responsiveProps => (
        <Flex direction="column">
          <Flex.Item shouldGrow shouldShrink>
            <Flex direction={props.isTopic ? responsiveProps.direction : 'row'}>
              {props.author && (
                <Flex.Item
                  shouldGrow
                  shouldShrink
                  overflowX="hidden"
                  overflowY="hidden"
                  padding={responsiveProps.authorInfo.padding}
                >
                  <AuthorInfo
                    author={props.author}
                    editor={props.editor}
                    isUnread={props.isUnread}
                    isForcedRead={props.isForcedRead}
                    isIsolatedView={props.isIsolatedView}
                    timingDisplay={props.timingDisplay}
                    editedTimingDisplay={props.editedTimingDisplay}
                    lastReplyAtDisplay={props.lastReplyAtDisplay}
                    showCreatedAsTooltip={!props.isTopic}
                  />
                </Flex.Item>
              )}
              <Flex.Item
                align={responsiveProps.postUtilities.align}
                margin={props.author ? responsiveProps.postUtilities.margin : '0'}
                overflowX="hidden"
                overflowY="hidden"
                shouldGrow={!props.author}
                padding={responsiveProps.postUtilities.padding}
              >
                {props.postUtilities}
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item
            padding={
              props.author
                ? responsiveProps.postMessage.padding
                : responsiveProps.postMessage.paddingNoAuthor
            }
            margin={props.isTopic ? '0' : responsiveProps.postMessage.margin}
            overflowY="hidden"
            overflowX="hidden"
          >
            <PostMessage
              title={props.title}
              message={props.message}
              isEditing={props.isEditing}
              onSave={props.onSave}
              onCancel={props.onCancel}
              isIsolatedView={props.isIsolatedView}
            >
              {props.children}
            </PostMessage>
          </Flex.Item>
        </Flex>
      )}
    />
  )
}

PostContainer.propTypes = {
  isTopic: PropTypes.bool,
  postUtilities: PropTypes.node,
  author: User.shape,
  children: PropTypes.node,
  title: PropTypes.string,
  message: PropTypes.string,
  isEditing: PropTypes.bool,
  onSave: PropTypes.func,
  onCancel: PropTypes.func,
  isIsolatedView: PropTypes.bool,
  editor: User.shape,
  isUnread: PropTypes.bool,
  isForcedRead: PropTypes.bool,
  timingDisplay: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  deleted: PropTypes.bool
}

PostContainer.defaultProps = {
  deleted: false
}
