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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {IconAddLine} from '@instructure/ui-icons'

const I18n = createI18nScope('enhanced-rubrics-assignment-search')

type RubricSearchFooterProps = {
  disabled: boolean
  onSubmit: () => void
  onCancel: () => void
}
export const RubricSearchFooter = ({disabled, onSubmit, onCancel}: RubricSearchFooterProps) => {
  return (
    <View
      as="div"
      data-testid="rubric-assessment-footer"
      overflowX="hidden"
      overflowY="hidden"
      background="secondary"
      padding="0 small"
    >
      <Flex justifyItems="end" margin="small 0">
        <Flex.Item margin="0 small 0 0">
          <Button
            color="secondary"
            onClick={() => onCancel()}
            data-testid="cancel-rubric-search-button"
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            color="primary"
            // @ts-expect-error - InstUI Button renderIcon prop type mismatch
            renderIcon={IconAddLine}
            onClick={() => onSubmit()}
            data-testid="save-rubric-assessment-button"
            disabled={disabled}
          >
            {I18n.t('Add')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
