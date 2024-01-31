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
import {useActionData, useLoaderData, useNavigate} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconDownloadLine,
  IconEditLine,
  IconPrinterLine,
  IconReviewScreenLine,
  IconShareLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import type {ProjectDetailData} from '../../types'
import ProjectView from './ProjectView'
import ProjectPreviewModal from './ProjectPreviewModal'
import {showUnimplemented} from '../../shared/utils'

const ProjectViewPage = () => {
  const navigate = useNavigate()
  const create_project = useActionData() as ProjectDetailData
  const edit_project = useLoaderData() as ProjectDetailData
  const project = create_project || edit_project
  const [showPreview, setShowPreview] = useState(false)

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${project.id}`)
  }, [navigate, project.id])

  const handlePreviewClick = useCallback(() => {
    setShowPreview(true)
  }, [])

  const handleClosePreview = useCallback(() => {
    setShowPreview(false)
  }, [])

  return (
    <View as="div" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/learner/projects/dashboard`}>
          Projects
        </Breadcrumb.Link>
        <Breadcrumb.Link>{project.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="0 0 medium 0" justifyItems="end">
        <Flex.Item>
          <Button margin="0 x-small 0 0" renderIcon={IconEditLine} onClick={handleEditClick}>
            Edit
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconDownloadLine} onClick={showUnimplemented}>
            Download
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconPrinterLine} onClick={window.print}>
            Print
          </Button>
          <Button
            margin="0 x-small 0 0"
            renderIcon={IconReviewScreenLine}
            onClick={handlePreviewClick}
          >
            Preview
          </Button>
          <Button color="primary" margin="0" renderIcon={IconShareLine} onClick={showUnimplemented}>
            Share
          </Button>
        </Flex.Item>
      </Flex>
      <View as="div" shadow="above" margin="0 0 x-large 0">
        <ProjectView project={project} />
      </View>
      <ProjectPreviewModal project={project} open={showPreview} onClose={handleClosePreview} />
    </View>
  )
}

export default ProjectViewPage
