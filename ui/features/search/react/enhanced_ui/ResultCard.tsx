/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {
  IconAssignmentLine,
  IconDocumentLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconModuleLine,
  IconCalendarMonthLine,
  IconUnpublishLine,
} from '@instructure/ui-icons'
import stopwords from '../stopwords'
import type {Module, Result} from '../types'
import {htmlEscape} from '@instructure/html-escape'
import {Pill} from '@instructure/ui-pill'
import {fudgeDateForProfileTimezone} from '@canvas/datetime/date-functions'

const I18n = createI18nScope('SmartSearch')

const icon_class = (content_type: string) => {
  switch (content_type) {
    case 'Assignment':
      return <IconAssignmentLine color="brand" size="x-small" data-testid="assignment_icon" />
    case 'Announcement':
      return <IconAnnouncementLine color="brand" size="x-small" data-testid="announcement_icon" />
    case 'DiscussionTopic':
      return <IconDiscussionLine color="brand" size="x-small" data-testid="discussion_icon" />
    default:
      return <IconDocumentLine color="brand" size="x-small" data-testid="document_icon" />
  }
}

const MAX_MODULES_SHOWN = 5

interface Props {
  result: Result
  searchTerm: string
}

export default function ResultCard(props: Props) {
  // TODO: update styling
  // TODO: add module list and tags

  const {body, content_type, html_url, readable_type, title} = props.result

  const getHighlightedSegment = (searchTerm: string, text: string, maxTokens: number) => {
    // Split the searchTerm into tokens
    const searchTerms = searchTerm.split(' ')

    // Filter out single character search terms and common words
    const validSearchTerms = searchTerms.filter(
      term => term.length > 1 && !stopwords.includes(term.toLowerCase()),
    )

    // Escape each searchTerm and join them with '|'
    const escapedSearchTerms = validSearchTerms
      .map(term => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
      .join('|')

    // Create a RegExp that matches any of the searchTerms
    // TODO: prefix this regex with a word boundry \\b to avoid substrings
    // or figure out a way to remove stop words from the search terms
    const searchExpression = new RegExp(`(${escapedSearchTerms})`, 'gi')

    // Remove HTML tags and split the text into words
    const words = text.replace(/<[^>]*>/gm, '').split(' ')

    // Calculate the concentration of highlight words in each segment of maxTokens words
    let segmentIndex = 0
    let truncatedText = text
    if (words.length > maxTokens) {
      const segments = []
      for (let i = 0; i < words.length; i += maxTokens) {
        const segment = words.slice(i, i + maxTokens)
        const highlightCount = segment.filter(word => searchExpression.test(word)).length
        const concentration = highlightCount / segment.length
        segments.push({segment, concentration, segmentIndex: i / maxTokens})
      }

      // Keep the segment with the highest concentration
      const segmentRecord = segments.sort((a, b) => b.concentration - a.concentration)[0]

      // Join the words back into a string and add ellipses if the segment is not the first or last
      truncatedText = segmentRecord.segment.join(' ')
      segmentIndex = segmentRecord.segmentIndex
      if (segmentIndex > 0) {
        truncatedText = '...' + truncatedText
      }
      if (segmentIndex < segments.length - 1) {
        truncatedText += '...'
      }
    }

    return {truncatedText, searchExpression}
  }

  const addSearchHighlighting = (searchTerm: string, text: string) => {
    const maxTokens = 128
    const {truncatedText, searchExpression} = getHighlightedSegment(searchTerm, text, maxTokens)

    return truncatedText.replace(
      searchExpression,
      '<span data-testid="highlighted-search-item" style="background-color: rgba(0,142,226,0.2); border-radius: .25rem; padding-bottom: 3px; padding-top: 1px;">$1</span>',
    )
  }

  const renderModuleList = (modules: Module[]) => {
    let trimmedModules = modules
    let extraModuleText = null
    if (modules.length > MAX_MODULES_SHOWN) {
      trimmedModules = modules.slice(0, MAX_MODULES_SHOWN)
      extraModuleText = I18n.t(
        {one: '%{count} other module', other: '%{count} other modules'},
        {
          count: modules.length - MAX_MODULES_SHOWN,
        },
      )
    }
    return (
      <Flex gap="xx-small">
        {trimmedModules.map((module: Module, index: number) => (
          <Flex key={module.id} gap="xx-small">
            <IconModuleLine data-testid="module_icon" />
            <Text size="small">{module.name}</Text>
            {index < modules.length - 1 || extraModuleText != null ? <span> | </span> : null}
          </Flex>
        ))}
        {extraModuleText != null ? (
          <Text key="extra-modules" size="small">
            {extraModuleText}
          </Text>
        ) : null}
      </Flex>
    )
  }

  const renderPills = (id: string, dueDate: string | null, published: boolean | null) => {
    let datePill,
      publishPill = null
    if (dueDate != null) {
      const fudgedDate = fudgeDateForProfileTimezone(new Date(dueDate))
      datePill = (
        <Pill data-testid={`${id}-due`} renderIcon={<IconCalendarMonthLine />}>
          {I18n.t('Due %{date}', {
            date: fudgedDate!.toLocaleDateString(undefined, {month: 'short', day: 'numeric'}),
          })}
        </Pill>
      )
    }
    if (published === false) {
      publishPill = (
        <Pill data-testid={`${id}-publish`} renderIcon={<IconUnpublishLine />}>
          {I18n.t('Unpublished')}
        </Pill>
      )
    }
    return (
      <Flex gap="x-small">
        {datePill}
        {publishPill}
      </Flex>
    )
  }

  return (
    <Flex
      alignItems="start"
      direction="column"
      gap="xx-small"
      justifyItems="space-between"
      data-testid="search-result"
    >
      <Heading as="h2" level="h3">
        {title}
      </Heading>
      <Link
        href={html_url}
        isWithinText={false}
        target="_blank"
        renderIcon={icon_class(content_type)}
      >
        {readable_type}
      </Link>
      {renderPills(
        `${props.result.content_id}-${props.result.content_type}`,
        props.result.due_date ?? null,
        props.result.published ?? null,
      )}
      <Text
        as="p"
        dangerouslySetInnerHTML={{
          __html: addSearchHighlighting(props.searchTerm, htmlEscape(body)),
        }}
      />
      {props.result.modules && renderModuleList(props.result.modules)}
    </Flex>
  )
}
