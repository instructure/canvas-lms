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
import {useLoaderData} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import type {PathwayViewDetailData} from '../../types'
import PathwayView from './PathwayView'

const PathwayViewPage = () => {
  const pathway = useLoaderData() as PathwayViewDetailData

  return (
    <Flex as="div" direction="column" gap="small" alignItems="stretch">
      <View as="div" margin="0 x-large">
        <Breadcrumb label="You are here:" size="small">
          <Breadcrumb.Link href={`/users/${ENV.current_user.id}/passport/admin/pathways/dashboard`}>
            Pathways
          </Breadcrumb.Link>
          <Breadcrumb.Link>{pathway.title}</Breadcrumb.Link>
        </Breadcrumb>
        <View as="div" margin="0 0 medium 0">
          <Heading level="h1">{pathway.title}</Heading>
        </View>
      </View>
      <Flex.Item shouldGrow={true}>
        <View as="div" overflowX="auto" overflowY="visible">
          <PathwayView pathway={pathway} />
        </View>
      </Flex.Item>
    </Flex>
  )
}

export default PathwayViewPage
