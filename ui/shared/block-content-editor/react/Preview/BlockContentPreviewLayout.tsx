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

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

export const BlockContentPreviewLayout = (props: {
  selectorbar: React.ReactNode
  preview: React.ReactNode
}) => {
  return (
    <View
      background="secondary"
      padding="medium large"
      height="100%"
      data-testid="block-content-preview-layout"
    >
      <Flex direction="column" gap="medium" alignItems="center">
        {props.selectorbar}
        {props.preview}
      </Flex>
    </View>
  )
}
