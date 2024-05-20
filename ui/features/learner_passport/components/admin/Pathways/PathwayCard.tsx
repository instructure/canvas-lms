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

// not really a card, but a row in the Pathways dashboard's table

import React, {useCallback, useState} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconCopyLine,
  IconDownloadLine,
  IconEditLine,
  IconLinkLine,
  IconMoreLine,
  IconResetLine,
  IconReviewScreenLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import type {MenuItemProps} from '@instructure/ui-menu'
import {Pill} from '@instructure/ui-pill'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {ProgressCircle} from '@instructure/ui-progress'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewOwnProps} from '@instructure/ui-view'
import type {PathwayData} from '../../types'
import {formatDate2} from '../../shared/utils'

export type PathwayCardProps = {
  pathway: PathwayData
  onAction: (pathwayId: string, action: string) => void
}

const PathwayCard = ({pathway, onAction}: PathwayCardProps) => {
  const [kabobButtonRef, setKabobButtonRef] = useState<Element | null>(null)

  const handleCardClick = useCallback(
    (e: React.MouseEvent<ViewOwnProps, MouseEvent>) => {
      if (e.target === kabobButtonRef) return
      onAction(pathway.id, 'view')
    },
    [kabobButtonRef, onAction, pathway.id]
  )

  const handleKabobMenuSelect = useCallback(
    (
      e: React.MouseEvent<Element, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][]
    ) => {
      e.preventDefault()
      e.stopPropagation()
      if (!value) return
      if (typeof value !== 'string') return
      onAction(pathway.id, value)
    },
    [onAction, pathway.id]
  )

  const renderPathwayOverview = () => {
    return (
      <View as="div">
        <View as="div">
          <Link isWithinText={false} onClick={handleCardClick}>
            <Text weight="bold">{pathway.title}</Text>
          </Link>
        </View>
        <View as="div" margin="x-small 0 0 0">
          <Text size="small">{pathway.milestoneCount} Milestones</Text> |{' '}
          <Text size="small">{pathway.requirementCount} Requirements</Text>
        </View>
        <View as="div" margin="x-small 0 0 0">
          {pathway.published ? <Pill color="success">Published</Pill> : <Pill>Draft</Pill>}
        </View>
      </View>
    )
  }

  return (
    <Table.Row key={pathway.id} data-pathwayid={pathway.id}>
      <Table.Cell>{renderPathwayOverview()}</Table.Cell>
      <Table.Cell>
        {pathway.published ? formatDate2(new Date(pathway.published)) : '\u2014'}
      </Table.Cell>
      <Table.Cell>
        <PresentationContent>
          <ProgressCircle
            screenReaderLabel="started progress"
            size="x-small"
            valueNow={pathway.started_count}
            valueMax={pathway.enrolled_student_count}
          />
        </PresentationContent>
        <Text>
          {pathway.started_count}/{pathway.enrolled_student_count}
        </Text>
      </Table.Cell>
      <Table.Cell>
        <PresentationContent>
          <ProgressCircle
            screenReaderLabel="started progress"
            size="x-small"
            valueNow={pathway.completed_count}
            valueMax={pathway.enrolled_student_count}
          />
        </PresentationContent>
        <Text>
          {pathway.completed_count}/{pathway.enrolled_student_count}
        </Text>
      </Table.Cell>
      <Table.Cell>
        <Menu
          onSelect={handleKabobMenuSelect}
          placement="bottom"
          trigger={
            <IconButton
              elementRef={(el: Element | null) => setKabobButtonRef(el)}
              screenReaderLabel="More"
              withBackground={false}
              withBorder={false}
            >
              <IconMoreLine />
            </IconButton>
          }
        >
          <Menu.Item value="view">
            <IconReviewScreenLine /> View
          </Menu.Item>
          <Menu.Item value="edit">
            <IconEditLine /> Edit
          </Menu.Item>
          <Menu.Item value="duplicate">
            <IconCopyLine /> Duplicate
          </Menu.Item>
          <Menu.Item value="download">
            <IconDownloadLine /> Download
          </Menu.Item>
          <Menu.Item value="rename">
            <IconEditLine /> Rename
          </Menu.Item>
          <Menu.Item value="share">
            <IconLinkLine /> Copy share link
          </Menu.Item>
          <Menu.Item value="regen_share">
            <IconResetLine /> Regenerate share link
          </Menu.Item>
          <Menu.Item value="delete">
            <IconTrashLine /> Delete
          </Menu.Item>
        </Menu>
      </Table.Cell>
    </Table.Row>
  )
}

PathwayCard.displayName = 'Row'

export default PathwayCard
