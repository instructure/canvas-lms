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
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export const LoadingContainer = (props: {loadingText: string}) => {
  return (
    <Flex height="500px" alignItems="start" as="div">
      <View as="div">
        <Spinner size="small" renderTitle={props.loadingText} />
        <Text>{props.loadingText}</Text>
      </View>
    </Flex>
  )
}
