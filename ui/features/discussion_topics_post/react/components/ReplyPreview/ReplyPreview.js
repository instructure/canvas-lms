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

import DateHelper from '../../../../../shared/datetime/dateHelper'
import I18n from 'i18n!discussion_topics_post'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'

import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export const ReplyPreview = ({...props}) => {
  const message = props.deleted
    ? I18n.t('Deleted by %{editor}', {editor: props.editor.shortName})
    : props.previewMessage

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          textSize: 'x-small'
        },
        desktop: {
          textSize: 'small'
        }
      }}
      render={responsiveProps => (
        <View
          as="div"
          borderWidth="0 0 0 large"
          data-testid="reply-preview"
          margin="0 0 medium 0"
          padding="x-small 0 x-small medium"
        >
          <Flex direction="column">
            <Flex.Item>
              <View>
                <Text weight="bold" size={responsiveProps.textSize}>
                  {props.author.shortName}
                </Text>
              </View>
            </Flex.Item>
            <Flex.Item>
              <View>
                <Text size="x-small">
                  {DateHelper.formatDatetimeForDiscussions(props.createdAt)}
                </Text>
              </View>
            </Flex.Item>
            <Flex.Item margin="small 0 0 0">
              <Text size={responsiveProps.textSize}>{message}</Text>
            </Flex.Item>
          </Flex>
        </View>
      )}
    />
  )
}

ReplyPreview.propTypes = {
  /**
   * Quoted author
   */
  author: PropTypes.object,
  /**
   * Editor of the quoted message
   */
  editor: PropTypes.object,
  /**
   * Quoted reply created at date
   */
  createdAt: PropTypes.string,
  /**
   * Quoted message
   */
  previewMessage: PropTypes.string,
  /**
   * True if the quoted message has been deleted
   */
  deleted: PropTypes.bool
}
