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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {AddButton} from './AddButton'
import {useGetBlocksCount} from '../hooks/useGetBlocksCount'
import {useAddBlockModal} from '../hooks/useAddBlockModal'

const I18n = createI18nScope('block_content_editor')

export const AddBlock = () => {
  const {open} = useAddBlockModal()
  const {blocksCount} = useGetBlocksCount()
  if (blocksCount > 0) {
    return null
  }

  return (
    <View borderWidth="small" borderRadius="medium">
      <Flex direction="column" padding="large" gap="large" alignItems="center">
        <Heading data-testid="add-block-heading" variant="titleCardSection">
          {I18n.t('Add a block')}
        </Heading>
        <Flex direction="column" alignItems="center">
          <span style={{textAlign: 'center'}}>
            {I18n.t('A block is a building element of your page. It helps you organize content.')}
          </span>
          <span style={{textAlign: 'center'}}>
            {I18n.t(
              'You can add, customize, and rearrange blocks to create a structured and engaging page.',
            )}
          </span>
        </Flex>
        <AddButton onClicked={open} />
      </Flex>
    </View>
  )
}
