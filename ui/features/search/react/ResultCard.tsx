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
import {Flex} from '@instructure/ui-flex'
import {
  IconAssignmentLine,
  IconDocumentLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconModuleLine,
  IconCalendarMonthLine,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import type {Module, Result} from './types'
import {htmlEscape} from '@instructure/html-escape'
import {Pill} from '@instructure/ui-pill'
import {fudgeDateForProfileTimezone} from '@canvas/datetime/date-functions'
import {addSearchHighlighting} from './searchHighlighting'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'

const I18n = createI18nScope('SmartSearch')

function iconClass(content_type: string): React.JSX.Element {
  switch (content_type) {
    case 'Assignment':
      return (
        <IconAssignmentLine size="x-small" data-testid="assignment_icon" key="assignment_icon" />
      )
    case 'Announcement':
      return (
        <IconAnnouncementLine
          size="x-small"
          data-testid="announcement_icon"
          key="announcement_icon"
        />
      )
    case 'DiscussionTopic':
      return (
        <IconDiscussionLine size="x-small" data-testid="discussion_icon" key="discussion_icon" />
      )
    default:
      return <IconDocumentLine size="x-small" data-testid="document_icon" key="document_icon" />
  }
}

const MAX_MODULES_SHOWN = 5

export interface ResultCardProps {
  result: Result
  resultType: 'best' | 'similar'
  searchTerm: string
}

export default function ResultCard(props: ResultCardProps): React.JSX.Element {
  const {body, content_type, html_url, title, readable_type} = props.result

  function renderModuleList(modules: Module[]): React.JSX.Element | null {
    let trimmedModules = modules
    let extraModuleText: string | null = null
    if (modules.length > MAX_MODULES_SHOWN) {
      trimmedModules = modules.slice(0, MAX_MODULES_SHOWN)
      extraModuleText = I18n.t(
        {one: '%{count} other module', other: '%{count} other modules'},
        {
          count: modules.length - MAX_MODULES_SHOWN,
        },
      )
    }
    if (trimmedModules.length === 0) return null

    return (
      <Flex gap="space8" key="module-list" wrap="wrap">
        {trimmedModules.map((module: Module, index: number) => (
          <Flex key={`module-item-${module.id}`} gap="space8">
            <IconModuleLine data-testid="module_icon" />
            <Text key={`module-name-${module.id}`} variant="contentSmall" wrap="break-word">
              {module.name}
            </Text>
            {index < modules.length - 1 || extraModuleText ? (
              <span key={`module-separator-${index}`}> | </span>
            ) : null}
          </Flex>
        ))}
        {extraModuleText ? (
          <Text key="extra-modules" variant="contentSmall">
            {extraModuleText}
          </Text>
        ) : null}
      </Flex>
    )
  }

  function renderPills(
    id: string,
    dueDate: string | null,
    published: boolean | null,
  ): React.JSX.Element {
    const pills = [
      iconClass(content_type),
      <Text variant="content" key="content-type">
        {readable_type}
      </Text>,
    ]
    if (dueDate) {
      const fudgedDate = fudgeDateForProfileTimezone(new Date(dueDate))
      pills.push(
        <Pill data-testid={`${id}-due`} renderIcon={<IconCalendarMonthLine />} key="due-date">
          {I18n.t('Due %{date}', {
            date: fudgedDate!.toLocaleDateString(undefined, {month: 'short', day: 'numeric'}),
          })}
        </Pill>,
      )
    }
    if (published === false) {
      pills.push(
        <Pill data-testid={`${id}-publish`} renderIcon={<IconUnpublishedLine />} key="unpublished">
          {I18n.t('Unpublished')}
        </Pill>,
      )
    }
    return (
      <Flex key="result-pills" gap="space8" alignItems="center" wrap="wrap">
        {pills}
      </Flex>
    )
  }

  return (
    <List margin="none" itemSpacing="none" delimiter="none" isUnstyled={true}>
      <List.Item>
        <Flex
          key={`${props.result.content_id}-${props.result.content_type}`}
          alignItems="start"
          direction="column"
          gap="space8"
          justifyItems="space-between"
          data-testid="search-result"
          width="100%"
        >
          <Link href={html_url} target="_blank" key="result-link">
            <Text
              size="descriptionPage"
              weight="weightImportant"
              data-pendo={`smart-search-${props.resultType}-result`}
              wrap="break-word"
            >
              {title}
            </Text>
          </Link>
          {renderPills(
            `${props.result.content_id}-${props.result.content_type}`,
            props.result.due_date ?? null,
            props.result.published ?? null,
          )}
          <Text
            key="result-body"
            variant="content"
            wrap="break-word"
            dangerouslySetInnerHTML={{
              __html: addSearchHighlighting(props.searchTerm, htmlEscape(body)),
            }}
          />
          {props.result.modules && renderModuleList(props.result.modules)}
        </Flex>
      </List.Item>
    </List>
  )
}
