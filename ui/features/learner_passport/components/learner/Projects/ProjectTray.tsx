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

import React, {useCallback, useState} from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import type {ProjectDetailData} from '../../types'
import ProjectView from './ProjectView'

interface ProjectPreviewModalProps {
  open: boolean
  project?: ProjectDetailData
  onClose: () => void
}

const ProjectPreviewModal = ({open, project, onClose}: ProjectPreviewModalProps) => {
  const [trayHeadingIsTruncated, setTrayHeadingIsTruncated] = useState(false)

  const handleTruncatedHeading = useCallback((isTruncated: boolean) => {
    setTrayHeadingIsTruncated(isTruncated)
  }, [])

  const renderTrayHeading = useCallback(() => {
    if (!project) return null

    return (
      <Heading margin="0 large 0 0">
        <TruncateText onUpdate={handleTruncatedHeading}>{project.title}</TruncateText>
      </Heading>
    )
  }, [handleTruncatedHeading, project])

  const renderTrayHeader = useCallback(() => {
    if (!project) return null

    return trayHeadingIsTruncated ? (
      <Tooltip renderTip={project.title}>{renderTrayHeading()}</Tooltip>
    ) : (
      renderTrayHeading()
    )
  }, [project, renderTrayHeading, trayHeadingIsTruncated])

  return (
    <Tray label="Project Details" open={open} onDismiss={onClose} size="regular" placement="end">
      <Flex as="div" padding="small small small medium">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          {renderTrayHeader()}
        </Flex.Item>
        <Flex.Item>
          <CloseButton placement="end" offset="small" screenReaderLabel="Close" onClick={onClose} />
        </Flex.Item>
      </Flex>
      <View as="div" maxWidth="986px" margin="0 auto" background="primary" shadow="resting">
        {project ? <ProjectView project={project} inTray={true} /> : null}
      </View>
    </Tray>
  )
}

export default ProjectPreviewModal
