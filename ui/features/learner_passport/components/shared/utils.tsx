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
import {
  IconLinkLine,
  IconMsWordLine,
  IconPdfLine,
  IconImageLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import type {AchievementData} from '../types'
import AchievementCard from '../Achievements/AchievementCard'

export function stringToId(s: string): string {
  return s.replace(/\W+/g, '-')
}

type hasFromToDates = {
  from_date: string
  to_date: string
}

export function compareFromToDates(a: hasFromToDates, b: hasFromToDates) {
  if (a.from_date < b.from_date) {
    return 1
  }
  if (a.from_date > b.from_date) {
    return -1
  }
  return 0
}

export const formatDate = (date: string | Date) => {
  return new Intl.DateTimeFormat(ENV.LOCALE || 'en', {month: 'short', year: 'numeric'}).format(
    new Date(date)
  )
}

export function isUrlToLocalCanvasFile(url: string): boolean {
  const fileURL = new URL(url, window.location.origin)

  const matchesCanvasFile = /(?:\/(courses|groups|users)\/(\d+))?\/files\/(\d+)/.test(
    fileURL.pathname
  )

  return matchesCanvasFile && fileURL.origin === window.location.origin
}

export function renderFileTypeIcon(contentType: string) {
  if (contentType === 'application/pdf') return <IconPdfLine />
  if (contentType === 'application/msword') return <IconMsWordLine />
  if (contentType.startsWith('image/')) return <IconImageLine />
  return (
    <SVGIcon src='<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1rem" height="1rem"> </svg>' />
  )
}

export function renderLink(link: string) {
  return (
    <List.Item key={link.replace(/\W+/, '-')}>
      <Link href={link} renderIcon={<IconLinkLine color="primary" size="x-small" />}>
        {link}
      </Link>
    </List.Item>
  )
}

export const renderEditLink = (
  link: string,
  onEditLink: (event: React.FocusEvent<HTMLInputElement>) => void,
  onDeleteLink: (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => void
) => {
  const id = stringToId(link) || uid('link', 2)
  return (
    <Flex as="div" gap="small" key={id}>
      <TextInput
        id={id}
        name="links[]"
        renderLabel={<ScreenReaderContent>Link</ScreenReaderContent>}
        renderBeforeInput={IconLinkLine}
        display="inline-block"
        width="30rem"
        defaultValue={link}
        onBlur={onEditLink}
      />
      <IconButton
        screenReaderLabel="delete link"
        size="small"
        data-linkid={id}
        onClick={onDeleteLink}
      >
        <IconTrashLine />
      </IconButton>
    </Flex>
  )
}

export function renderAchievement(achievement: AchievementData) {
  return (
    <View as="div" shadow="resting">
      <AchievementCard
        isNew={achievement.isNew}
        title={achievement.title}
        issuer={achievement.issuer.name}
        imageUrl={achievement.imageUrl}
      />
    </View>
  )
}
