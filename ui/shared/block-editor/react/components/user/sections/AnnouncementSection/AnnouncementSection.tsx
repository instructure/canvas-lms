/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'

import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import {IconAnnouncementSolid} from '@instructure/ui-icons'
import {SectionMenu} from '../../../editor/SectionMenu'

const WIDTH = 'auto'
const HEIGHT = 'auto'

type AnnouncementSectionProps = {
  announcementId?: string
}

const AnnouncementSection = ({announcementId}: AnnouncementSectionProps) => {
  const {actions, query, enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    actions: {setProp},
    connectors: {connect, drag},
  } = useNode()

  const renderAnnouncement = () => {
    return (
      <div className="announcement-section__empty">
        {enabled ? (
          <Button color="primary">Select Announcement</Button>
        ) : (
          <Text>No announcement has been selected</Text>
        )}
      </div>
    )
  }

  return (
    <div
      className="announcement-section"
      ref={ref => {
        ref && connect(drag(ref))
      }}
      style={{width: WIDTH, height: HEIGHT}}
    >
      <div className="block-header">
        <IconAnnouncementSolid size="x-small" inline={true} />
        <span className="block-header-title">Announcement</span>
      </div>
      {renderAnnouncement()}
      <Flex justifyItems="space-between" padding="small">
        <Flex.Item shouldGrow={true} />
      </Flex>
    </div>
  )
}

AnnouncementSection.craft = {
  displayName: 'Announcement',
  custom: {
    isSection: true,
  },
  related: {
    sectionMenu: SectionMenu,
  },
}

export {AnnouncementSection}
