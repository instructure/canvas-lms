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

import React, { useState } from 'react'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {
  IconLikeLine,
  IconLikeSolid,
  IconAssignmentLine,
  IconDocumentLine,
  IconAnnouncementLine,
  IconDiscussionLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import stopwords from "./stopwords"

const I18n = useI18nScope('SmartSearch')

const preview = (body, maxLength = 512) => {
  const preview = []
  const words = body.match(/\p{L}+/gu)

  if (words == null) {
    return ''
  }

  while (preview.join(' ').length < maxLength) {
    preview.push(words.shift())
  }

  return preview.join(' ') + '...'
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

export default function SearchResult({onExplain, onLike, onDislike, result, searchTerm}) {
  const {body, content_id, content_type, relevance, html_url, readable_type, title} = result

  const getHighlightedSegment = (searchTerm, text, maxTokens) => {
    // Split the searchTerm into tokens
    const searchTerms = searchTerm.split(' ');

    // Filter out single character search terms and common words
    const validSearchTerms = searchTerms.filter(term => term.length > 1 && !stopwords.includes(term.toLowerCase()))

    // Escape each searchTerm and join them with '|'
    const escapedSearchTerms = validSearchTerms.map(term => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');

    // Create a RegExp that matches any of the searchTerms
    // TODO: prefix this regex with a word boundry \\b to avoid substrings
    // or figure out a way to remove stop words from the search terms
    const searchExpression = new RegExp(`(${escapedSearchTerms})`, 'gi');

    // Remove HTML tags and split the text into words
    const words = text.replace(/<[^>]*>/gm, '').split(' ');

    // Calculate the concentration of highlight words in each segment of maxTokens words
    let segmentIndex = 0;
    let truncatedText = text;
    if(words.length > maxTokens) {
      const segments = [];
      for (let i = 0; i < words.length; i += maxTokens) {
        const segment = words.slice(i, i + maxTokens)
        const highlightCount = segment.filter(word => searchExpression.test(word)).length
        const concentration = highlightCount / segment.length;
        segments.push({ segment, concentration, segmentIndex: i / maxTokens })
      }

      // Keep the segment with the highest concentration
      let segmentRecord = segments.sort((a, b) => b.concentration - a.concentration)[0]

      // Join the words back into a string and add ellipses if the segment is not the first or last
      truncatedText = segmentRecord.segment.join(' ')
      segmentIndex = segmentRecord.segmentIndex
      if(segmentIndex > 0) {
        truncatedText = '...' + truncatedText
      }
      if(segmentIndex < segments.length - 1) {
        truncatedText += '...'
      }
    }

    return { truncatedText, searchExpression };
  }

  const addSearchHighlighting = (searchTerm, text) => {
    const maxTokens = 128
    const { truncatedText, searchExpression } = getHighlightedSegment(searchTerm, text, maxTokens)

    return truncatedText.replace(
      searchExpression,
      '<span data-testid="highlighted-search-item" style="background-color: rgba(0,142,226,0.2); border-radius: .25rem; padding-bottom: 3px; padding-top: 1px;">$1</span>'
    )
  }

  const [feedback, setFeedback] = useState()

  return (
    <View as="li" borderColor="primary" borderWidth="small 0 0 0" padding="medium 0">
      <Flex alignItems="start" as="div" gap="large" justifyItems="space-between">
        <Flex.Item shouldShrink={true} size="85%">
          <Heading as="h2" level="h3">
            {title}
          </Heading>

          <Link
            href={html_url}
            isWithinText={false}
            target="_blank"
            renderIcon={React.createElement(icon_class(content_type), {
              color: 'brand',
              size: 'x-small',
            })}
          >
            {readable_type}
          </Link>
          <Text
            as="p"
            size="small"
            dangerouslySetInnerHTML={{
              __html: addSearchHighlighting(searchTerm, body),
            }}
          />
        </Flex.Item>
        <Flex.Item shouldShrink={true}>
          <Flex gap="small">
            <Flex.Item as="div">
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
                onClick={_ => onLike({id: content_id, type: content_type}).then(_ => setFeedback("liked"))}
                screenReaderLabel={I18n.t('I like this result')}
                renderIcon={feedback === "liked" ? <IconLikeSolid color="brand" />: <IconLikeLine />}
                withBackground={false}
                withBorder={false}
              />
              <span style={{display: 'inline-block', transform: 'rotate(180deg)'}}>
                <IconButton
                  onClick={_ => onDislike({id: content_id, type: content_type}).then(_ => setFeedback("disliked"))}
                  screenReaderLabel={I18n.t('I do not like this result')}
                  renderIcon={feedback === "disliked" ? <IconLikeSolid color="brand" /> : <IconLikeLine />}
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
