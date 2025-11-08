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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_scan')

interface CourseScanWrapperProps {
  children: React.ReactNode
  scanButtonDisabled?: boolean
  handleCourseScan?: () => void
}

export const ScanHandler: React.FC<CourseScanWrapperProps> = ({
  children,
  scanButtonDisabled,
  handleCourseScan,
}) => {
  return (
    <View as="div">
      <Flex>
        <Flex.Item padding="x-small 0" shouldShrink shouldGrow>
          <Heading level="h1" as="h2" margin="0 0 x-small">
            {I18n.t('Course Accessibility Checker')}
          </Heading>
        </Flex.Item>
        <Flex.Item align="start">
          <Button
            color="primary"
            margin="small 0"
            disabled={scanButtonDisabled}
            onClick={handleCourseScan}
          >
            {I18n.t('Scan Course')}
          </Button>
        </Flex.Item>
      </Flex>
      {children}
    </View>
  )
}
