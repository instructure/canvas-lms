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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScanHandler} from './ScanHandler'

const I18n = createI18nScope('accessibility_scan')

export const ScanningInProgressView: React.FC = () => {
  return (
    <ScanHandler scanButtonDisabled={true}>
      <Flex justifyItems="center" margin="xx-large 0 small 0">
        <Flex.Item>
          <Spinner renderTitle={() => I18n.t('Scanning in progress')} size="small" />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <Text size="large">{I18n.t('Hang tight!')}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <View as="div" textAlign="center" maxWidth="24rem">
            <Text size="small">
              {I18n.t(
                'Scanning might take a few seconds or up to several minutes, depending on how much content your course contains.',
              )}
            </Text>
          </View>
        </Flex.Item>
      </Flex>
    </ScanHandler>
  )
}
