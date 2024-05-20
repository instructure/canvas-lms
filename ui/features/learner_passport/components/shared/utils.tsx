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
  IconDocumentLine,
  IconLinkLine,
  IconMsWordLine,
  IconPdfLine,
  IconImageLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {AchievementData, MilestoneData, ProjectDetailData} from '../types'
import AchievementCard from '../learner/Achievements/AchievementCard'
import ProjectCard from '../learner/Projects/ProjectCard'
import ClickableCard from './ClickableCard'

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

export const formatDate2 = (date: string | Date) => {
  return new Intl.DateTimeFormat(ENV.LOCALE || 'en', {
    day: 'numeric',
    month: 'numeric',
    year: 'numeric',
  }).format(new Date(date))
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
  return <IconDocumentLine />
}

export function renderLink(link: string) {
  return (
    <List.Item key={link.replace(/\W+/, '-')}>
      <Link
        href={link}
        target="_blank"
        renderIcon={<IconLinkLine color="primary" size="x-small" />}
      >
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

export function renderAchievement(
  achievement: AchievementData,
  onCardClick: (achievementId: string) => void
) {
  return (
    <View as="div" shadow="resting">
      <ClickableCard cardId={achievement.id} onClick={onCardClick}>
        <AchievementCard
          isNew={achievement.isNew}
          title={achievement.title}
          issuer={achievement.issuer.name}
          imageUrl={achievement.imageUrl}
        />
      </ClickableCard>
    </View>
  )
}

export function renderProject(project: ProjectDetailData, onClick: (projectId: string) => void) {
  return (
    <View as="div" shadow="resting">
      <ClickableCard cardId={project.id} onClick={onClick}>
        <ProjectCard project={project} />
      </ClickableCard>
    </View>
  )
}

export type FauxEvent = {
  currentTarget: {
    textContent: string
  }
}

export function showUnimplemented(
  event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps, MouseEvent> | FauxEvent
) {
  // @ts-expect-error
  const action = event.currentTarget.textContent
  showFlashAlert({
    message: `Sorry, ${action} is not implemented yet.`,
    type: 'info',
  })
}

export function showFilePreviewInOverlay(event: React.MouseEvent | React.KeyboardEvent) {
  let target: HTMLAnchorElement | null = null
  if ((event.target as HTMLAnchorElement)?.href) {
    target = event.target as HTMLAnchorElement
  } else if ((event.currentTarget as HTMLAnchorElement)?.href) {
    target = event.currentTarget as HTMLAnchorElement
  }
  if (!target) return
  const href = target.href
  if (!href) return

  const matches = href.match(/\/files\/(\d+~\d+|\d+)/)
  if (matches) {
    if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
      // if any modifier keys are pressed, do the browser default thing
      return
    }
    event.preventDefault()
    const origin = window.location.origin
    const url = new URL(href, origin)
    const verifier = url?.searchParams.get('verifier')
    const file_id = matches[1]
    // TODO:
    // 1. what window should be be using
    // 2. is that the right origin?
    // 3. this is temporary until we can decouple the file previewer from canvas
    window.top?.postMessage({subject: 'preview_file', file_id, verifier}, origin)
  }
}

export const previewBackgroundImage =
  "\"data:image/svg+xml,%3Csvg width='2647' height='2050' viewBox='0 0 2647 2050' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cg clip-path='url(%23clip0_1489_31002)'%3E%3Cg clip-path='url(%23clip1_1489_31002)'%3E%3Cpath opacity='0.1' fill-rule='evenodd' clip-rule='evenodd' d='M78.4791 -503.809C143.135 -465.585 175.865 -375.906 294.927 -286.202C413.47 -195.364 619.708 -105.956 675.481 24.624C731.578 156.017 638.053 328.262 496.755 419.345C354.615 510.748 166.191 522.299 -22.0959 524.431C-210.059 527.376 -396.397 522.211 -482.853 426.692C-569.633 330.358 -555.365 144.164 -522.141 3.2315C-488.917 -137.701 -436.088 -231.746 -375.948 -309.831C-316.65 -387.596 -248.874 -448.908 -167.179 -487.401C-84.3183 -525.399 13.3034 -540.899 78.4791 -503.809Z' fill='%236B7780'/%3E%3C/g%3E%3Cpath opacity='0.1' fill-rule='evenodd' clip-rule='evenodd' d='M2730.48 -503.809C2795.14 -465.585 2827.87 -375.906 2946.93 -286.202C3065.47 -195.364 3271.71 -105.956 3327.48 24.624C3383.58 156.017 3290.05 328.262 3148.76 419.345C3006.61 510.748 2818.19 522.299 2629.9 524.431C2441.94 527.376 2255.6 522.211 2169.15 426.692C2082.37 330.358 2096.63 144.164 2129.86 3.2315C2163.08 -137.701 2215.91 -231.746 2276.05 -309.831C2335.35 -387.596 2403.13 -448.908 2484.82 -487.401C2567.68 -525.399 2665.3 -540.899 2730.48 -503.809Z' fill='%236B7780'/%3E%3Cpath opacity='0.1' fill-rule='evenodd' clip-rule='evenodd' d='M2730.48 1546.19C2795.14 1584.42 2827.87 1674.09 2946.93 1763.8C3065.47 1854.64 3271.71 1944.04 3327.48 2074.62C3383.58 2206.02 3290.05 2378.26 3148.76 2469.35C3006.61 2560.75 2818.19 2572.3 2629.9 2574.43C2441.94 2577.38 2255.6 2572.21 2169.15 2476.69C2082.37 2380.36 2096.63 2194.16 2129.86 2053.23C2163.08 1912.3 2215.91 1818.25 2276.05 1740.17C2335.35 1662.4 2403.13 1601.09 2484.82 1562.6C2567.68 1524.6 2665.3 1509.1 2730.48 1546.19Z' fill='%236B7780'/%3E%3Cg clip-path='url(%23clip2_1489_31002)'%3E%3Cpath opacity='0.1' fill-rule='evenodd' clip-rule='evenodd' d='M78.4791 1546.19C143.135 1584.42 175.865 1674.09 294.927 1763.8C413.47 1854.64 619.708 1944.04 675.481 2074.62C731.578 2206.02 638.053 2378.26 496.755 2469.35C354.615 2560.75 166.191 2572.3 -22.0959 2574.43C-210.059 2577.38 -396.397 2572.21 -482.853 2476.69C-569.633 2380.36 -555.365 2194.16 -522.141 2053.23C-488.917 1912.3 -436.088 1818.25 -375.948 1740.17C-316.65 1662.4 -248.874 1601.09 -167.179 1562.6C-84.3183 1524.6 13.3034 1509.1 78.4791 1546.19Z' fill='%236B7780'/%3E%3C/g%3E%3Cpath opacity='0.1' fill-rule='evenodd' clip-rule='evenodd' d='M782.978 977.477C827.632 916.948 920.268 893.473 1021.73 783.979C1124.27 675.118 1234.33 478.731 1370.04 436.463C1506.59 393.956 1668.57 504.696 1744.86 654.767C1821.38 805.711 1813.67 994.635 1796.6 1182.46C1780.36 1370.05 1756.22 1555.19 1652.29 1631.61C1547.52 1708.26 1363.57 1675.07 1226.62 1627.61C1089.68 1580.14 1001.42 1517.92 929.798 1450.04C858.41 1383.03 804.268 1309.25 774.269 1223.93C744.88 1137.49 739.4 1038.64 782.978 977.477Z' fill='%236B7780'/%3E%3C/g%3E%3Cdefs%3E%3CclipPath id='clip0_1489_31002'%3E%3Crect width='2647' height='2050' fill='white'/%3E%3C/clipPath%3E%3CclipPath id='clip1_1489_31002'%3E%3Crect width='1240' height='525' fill='white' transform='translate(-548)'/%3E%3C/clipPath%3E%3CclipPath id='clip2_1489_31002'%3E%3Crect width='1240' height='525' fill='white' transform='translate(-548 1525)'/%3E%3C/clipPath%3E%3C/defs%3E%3C/svg%3E%0A\""

// this is overkill for what I need, but it was fun to learn
const pluralRules = new Intl.PluralRules(ENV.LOCALE || 'en-US')
export function pluralize(count: number, singular: string, plural: string) {
  const grammaticalNumber = pluralRules.select(count)
  switch (grammaticalNumber) {
    case 'one':
      return singular
    case 'other':
      return plural
    default:
      throw new Error('Unknown: ' + grammaticalNumber)
  }
}

export const findSubtreeMilestones = (
  milestones: MilestoneData[],
  rootId: string,
  subtree: string[]
): string[] => {
  const root = milestones.find(m => m.id === rootId)
  if (!root) return subtree
  subtree.push(rootId)
  if (root.next_milestones.length === 0) return subtree
  root?.next_milestones.forEach(nextid => {
    subtree.concat(findSubtreeMilestones(milestones, nextid, subtree))
  })
  return subtree
}
