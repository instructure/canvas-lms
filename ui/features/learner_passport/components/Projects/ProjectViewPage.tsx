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

import React, {useCallback} from 'react'
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
import type {ProjectDetailData} from '../types'
import ProjectView from './ProjectView'

const ProjectViewPage = () => {
  const navigate = useNavigate()
  const create_project = useActionData() as ProjectDetailData
  const edit_project = useLoaderData() as ProjectDetailData
  const project = create_project || edit_project

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${project.id}`)
  }, [navigate, project.id])

  return (
    <View as="div" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/projects/dashboard`}>
          Projects
        </Breadcrumb.Link>
        <Breadcrumb.Link>{project.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="0 0 medium 0" justifyItems="end">
        <Flex.Item>
          <Button margin="0 x-small 0 0" renderIcon={IconEditLine} onClick={handleEditClick}>
            Edit
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconDownloadLine}>
            Download
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconPrinterLine}>
            Print
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconReviewScreenLine}>
            Preview
          </Button>
          <Button color="primary" margin="0" renderIcon={IconShareLine}>
            Share
          </Button>
        </Flex.Item>
      </Flex>
      <ProjectView project={project} />
    </View>
  )
}

export default ProjectViewPage
