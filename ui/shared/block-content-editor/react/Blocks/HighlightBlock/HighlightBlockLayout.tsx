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

type HighlightBlockLayoutProps = {
  icon?: React.ReactNode
  content: React.ReactNode
  backgroundColor: string
}

export const HighlightBlockLayout = ({
  icon,
  content,
  backgroundColor,
}: HighlightBlockLayoutProps) => {
  return (
    <View
      data-testid="highlight-block"
      padding="medium"
      borderRadius="medium"
      color="primary"
      background="primary"
      themeOverride={{
        backgroundPrimary: backgroundColor,
      }}
      display="block"
    >
      <Flex gap="mediumSmall" direction="row">
        {icon && <Flex.Item data-testid="highlight-icon">{icon}</Flex.Item>}
        <Flex.Item shouldGrow shouldShrink>
          {content}
        </Flex.Item>
      </Flex>
    </View>
  )
}
