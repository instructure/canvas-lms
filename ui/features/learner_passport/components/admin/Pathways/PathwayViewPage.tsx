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
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData} from '../../types'
import AdminHeader from '../AdminHeader'
import PathwayView from './PathwayView'

const PathwayViewPage = () => {
  const pathway = useLoaderData() as PathwayDetailData

  return (
    <Flex as="div" direction="column" alignItems="stretch" height="100%">
      <AdminHeader
        title={<Heading level="h1">{pathway.title}</Heading>}
        breadcrumbs={[
          {
            text: 'Pathways',
            url: `/users/${ENV.current_user.id}/passport/admin/pathways/dashboard`,
          },
          {text: pathway.title},
        ]}
      />
      <Flex.Item shouldGrow={true} shouldShrink={false} overflowY="visible">
        <View
          as="div"
          id="pathway-view"
          borderWidth="small 0 0 0"
          height="100%"
          position="relative"
        >
          <div
            style={{
              position: 'absolute',
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              boxSizing: 'border-box',
            }}
          >
            <PathwayView pathway={pathway} />
          </div>
        </View>
      </Flex.Item>
    </Flex>
  )
}

export default PathwayViewPage
