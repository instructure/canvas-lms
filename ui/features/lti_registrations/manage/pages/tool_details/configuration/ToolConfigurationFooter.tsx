/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import * as React from 'react'

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

export type ToolConfigurationFooterProps = {
  children: React.ReactNode
}

export const ToolConfigurationFooter = React.memo(({children}: ToolConfigurationFooterProps) => {
  return (
    <div
      style={{
        position: 'sticky',
        bottom: '0',
      }}
    >
      <View
        as="div"
        margin="medium 0 0 0"
        borderWidth="small 0 0 0"
        borderColor="primary"
        padding="small 0"
        background="secondary"
      >
        {children}
      </View>
    </div>
  )
})
