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
import {ReactNode} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Responsive} from '@instructure/ui-responsive'

export const AddBlockModalBodyLayout = (props: {groupedSelect: ReactNode; preview: ReactNode}) => {
  return (
    <Responsive
      match="media"
      query={{small: {maxWidth: '767px'}, large: {minWidth: '768px'}}}
      render={(_, matches) => {
        if (matches?.includes('small')) {
          return (
            <Flex direction="column" gap="medium">
              <View>{props.groupedSelect}</View>
              <View borderWidth="small 0 0 0" borderColor="secondary" width="100%" />
              <View display="block" height="auto">
                {props.preview}
              </View>
            </Flex>
          )
        } else {
          return (
            <Flex direction="row" alignItems="start" gap="medium">
              <Flex.Item width="50%">{props.groupedSelect}</Flex.Item>
              <Flex.Item width="50%">
                <View
                  display="block"
                  borderWidth="0 0 0 small"
                  height="512px"
                  padding="medium"
                  borderColor="secondary"
                >
                  {props.preview}
                </View>
              </Flex.Item>
            </Flex>
          )
        }
      }}
    />
  )
}
