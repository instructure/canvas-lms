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
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-criterion-modal')

type RatingsHeaderProps = {
  criterionUseRange: boolean
  hidePoints: boolean
}
export const RatingsHeader = ({criterionUseRange, hidePoints}: RatingsHeaderProps) => {
  return (
    <View as="div" margin="medium 0 0 0" themeOverride={{marginMedium: '1.25rem'}}>
      <Flex>
        <Flex.Item>
          <View as="div" width="4.125rem">
            {I18n.t('Display')}
          </View>
        </Flex.Item>
        {!hidePoints && (
          <Flex.Item>
            <View as="div" width={criterionUseRange ? '14.375rem' : '9.875rem'}>
              {criterionUseRange ? I18n.t('Point Range') : I18n.t('Points')}
            </View>
          </Flex.Item>
        )}
        <Flex.Item>
          <View as="div" width="8.875rem" margin={hidePoints ? '0 0 0 x-large' : '0'}>
            {I18n.t('Rating Name')}
          </View>
        </Flex.Item>
        <Flex.Item>
          <View as="div" margin="0 0 0 small" themeOverride={{marginSmall: '1rem'}}>
            {I18n.t('Rating Description')}
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}
