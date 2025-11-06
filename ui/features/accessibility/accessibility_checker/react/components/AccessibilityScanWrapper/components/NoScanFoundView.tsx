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
import {Text} from '@instructure/ui-text'
import {CondensedButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import {ScanHandler} from './ScanHandler'
import type {ScanViewProps} from '../types'

const I18n = createI18nScope('accessibility_scan')

export const NoScanFoundView: React.FC<ScanViewProps> = ({handleCourseScan, isRequestLoading}) => {
  return (
    <ScanHandler handleCourseScan={handleCourseScan} scanButtonDisabled={isRequestLoading}>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <EmptyDesert />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <Text>{I18n.t("You haven't scanned your course yet")}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <CondensedButton disabled={isRequestLoading} onClick={handleCourseScan}>
            {I18n.t('Scan Course')}
          </CondensedButton>
        </Flex.Item>
      </Flex>
    </ScanHandler>
  )
}
