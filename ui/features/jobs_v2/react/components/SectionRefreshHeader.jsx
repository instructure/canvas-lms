/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import RefreshWidget from './RefreshWidget'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'

export default function SectionRefreshHeader({
  title,
  loadingTitle,
  loading,
  autoRefresh,
  onRefresh,
}) {
  return (
    <>
      <Flex alignItems="end">
        <Flex.Item>
          <Heading level="h2" margin="x-large 0 small 0">
            {title}
          </Heading>
        </Flex.Item>
        <Flex.Item padding="large 0 x-small x-small">
          <RefreshWidget
            autoRefresh={autoRefresh}
            onRefresh={onRefresh}
            title={loadingTitle}
            loading={loading}
          />
        </Flex.Item>
      </Flex>
    </>
  )
}
