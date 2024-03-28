/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {ProgressBar} from '@instructure/ui-progress'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconLikeLine, IconAssignmentLine, IconDocumentLine, IconAnnouncementLine, IconDiscussionLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('SmartSearch')

const preview = (body, maxLength = 512) => {
  const preview = []
  const words = body.match(/\w+/g)

  if(words == null) {
    return ''
  }

  while (preview.join(' ').length < maxLength) {
    preview.push(words.shift())
  }

  return preview.join(' ') + '...'
}

const relevance = distance => {
  return Math.round(100.0 * (1.0 - distance))
}

const icon_class = content_type => {
  switch (content_type) {
    case 'Assignment':
      return IconAssignmentLine
    case 'Announcement':
      return IconAnnouncementLine
    case 'DiscussionTopic':
      return IconDiscussionLine
    default:
      return IconDocumentLine
  }
}

export default function SearchResult({onExplain, onLike, onDislike, result}) {
  const {body, content_id, content_type, distance, html_url, readable_type, title} = result

  return (
    <View as="li" borderColor="primary" borderWidth="small 0 0 0" padding="medium 0">
      <Flex alignItems={'start'} as="div" gap="large" justifyItems={'space-between'}>
        <Flex.Item shouldShrink={true} size="60%">
          <Heading as={'h2'} level={'h3'}>
            {title}
          </Heading>

          <Link href={html_url} isWithinText={false} renderIcon={React.createElement(icon_class(content_type), {color: 'brand', size: 'x-small'})}>
            {readable_type}
          </Link>

          <Text as="p" size="small">
            {preview(body)}
          </Text>
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <Flex gap="small">
            <Flex.Item as="div">
              <Text size={'small'} weight="bold">
                {I18n.t('%{percent}% Relevance', {percent: relevance(distance)})}
              </Text>
              <ProgressBar
                meterColor="success"
                size={'x-small'}
                screenReaderLabel={I18n.t('Relevance')}
                valueNow={relevance(distance)}
                valueMax={100}
                width={'150px'}
              />
              <span className="hidden">
                <Text size="small">
                  <Link
                    as="button"
                    onClick={_ => onExplain({id: content_id, type: content_type})}
                    margin="small 0 0 0"
                  >
                    {I18n.t('Why was this result received?')}
                  </Link>
                </Text>
              </span>
            </Flex.Item>
            <Flex.Item>
              <IconButton
                onClick={_ => onLike({id: content_id, type: content_type})}
                screenReaderLabel={I18n.t('I like this result')}
                renderIcon={<IconLikeLine />}
                withBackground={false}
                withBorder={false}
              />
              <span style={{display: 'inline-block', transform: 'rotate(180deg)'}}>
                <IconButton
                  onClick={_ => onDislike({id: content_id, type: content_type})}
                  screenReaderLabel={I18n.t('I do not like this result')}
                  renderIcon={<IconLikeLine />}
                  withBackground={false}
                  withBorder={false}
                />
              </span>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}
