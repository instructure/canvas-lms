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

import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {getDisplayName, responsiveQuerySizes} from '../../utils'

import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {AccessibleContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('discussion_topics_post')

export const ReplyPreview = ({...props}) => {
  const [shouldShowTruncatedText, setShouldShowTruncatedText] = useState(true)
  const TRUNCATE_LENGTH = 170

  const deletedMessage = props.editor?.shortName
    ? I18n.t('Deleted by %{editor}', {editor: props.editor.shortName})
    : I18n.t('Deleted')
  const message = props.deleted ? deletedMessage : props.previewMessage

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          textSize: 'x-small',
        },
        desktop: {
          textSize: 'small',
        },
      }}
      render={responsiveProps => {
        const showTruncatedText = () => {
          return shouldShowTruncatedText && message.length > TRUNCATE_LENGTH ? (
            <Text
              size={responsiveProps.textSize}
              dangerouslySetInnerHTML={{__html: `${message.slice(0, 165)} ...`}}
            />
          ) : (
            <Text size={responsiveProps.textSize} dangerouslySetInnerHTML={{__html: message}} />
          )
        }

        const readMoreButtonText = shouldShowTruncatedText
          ? I18n.t('Read More')
          : I18n.t('Read Less')
        const author = getDisplayName(props)
        const readMoreButtonScreenReaderText = shouldShowTruncatedText
          ? I18n.t('Read More, Reply from %{author}', {author})
          : I18n.t('Read Less, Reply from %{author}', {author})

        return (
          <View
            as="div"
            borderWidth="0 0 0 large"
            data-testid="reply-preview"
            margin="0 0 medium 0"
          >
            <Flex direction="column" padding="x-small 0 x-small medium">
              <Flex.Item>
                <View>
                  <Text weight="bold" size={responsiveProps.textSize}>
                    {getDisplayName(props)}
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
                <Flex direction="column">
                  <Flex.Item>{showTruncatedText()}</Flex.Item>
                  {message.length > TRUNCATE_LENGTH && (
                    <Flex.Item>
                      <span className="discussions-show-more-text">
                        <Link
                          isWithinText={false}
                          as="button"
                          margin="small"
                          onClick={() => setShouldShowTruncatedText(!shouldShowTruncatedText)}
                        >
                          <AccessibleContent alt={readMoreButtonScreenReaderText}>
                            <Text size={responsiveProps.textSize}>{readMoreButtonText}</Text>
                          </AccessibleContent>
                        </Link>
                      </span>
                    </Flex.Item>
                  )}
                </Flex>
              </Flex.Item>
            </Flex>
          </View>
        )
      }}
    />
  )
}

ReplyPreview.propTypes = {
  /**
   * Quoted author
   */
  author: PropTypes.object,
  /**
   * Quoted anonymous author
   */
  anonymousAuthor: PropTypes.object,
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
  deleted: PropTypes.bool,
}
