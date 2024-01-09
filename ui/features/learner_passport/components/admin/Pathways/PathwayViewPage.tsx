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
import {useActionData, useLoaderData} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData} from '../../types'
import PathwayView from './PathwayView'
import {showUnimplemented} from '../../shared/utils'

const PathwayViewPage = () => {
  const create_pathway = useActionData() as PathwayDetailData
  const edit_pathway = useLoaderData() as PathwayDetailData
  const pathway = create_pathway || edit_pathway

  return (
    <View as="div" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/pathways/dashboard`}>
          Pathways
        </Breadcrumb.Link>
        <Breadcrumb.Link>{pathway.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="0 0 medium 0" justifyItems="end">
        <Flex.Item>
          <Button margin="0 x-small 0 0" onClick={showUnimplemented}>
            Save as Draft
          </Button>
          <Button margin="0 x-small 0 0" color="primary" onClick={showUnimplemented}>
            Next
          </Button>
        </Flex.Item>
      </Flex>
      <View as="div" borderWidth="small" borderColor="secondary" margin="0 0 x-large 0">
        <PathwayView pathway={pathway} />
      </View>
    </View>
  )
}

export default PathwayViewPage
