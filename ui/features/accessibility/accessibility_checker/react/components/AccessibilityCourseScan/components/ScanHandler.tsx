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
import {Responsive} from '@instructure/ui-responsive'
import {useScope as createI18nScope} from '@canvas/i18n'
import {responsiveQuerySizes} from '@canvas/breakpoints'

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
      <Responsive
        query={responsiveQuerySizes({mobile: true, desktop: true})}
        props={{
          mobile: {
            direction: 'column',
            buttonDisplay: 'block',
            buttonWidth: '100%',
            flexItemWidth: '100%',
          },
          desktop: {
            direction: 'row',
            buttonDisplay: 'inline-block',
            buttonWidth: 'auto',
            flexItemWidth: 'auto',
          },
        }}
        render={props => {
          if (!props) return null
          return (
            <Flex direction={props.direction} gap="medium">
              <Flex.Item padding="x-small 0" shouldShrink shouldGrow>
                <Heading level="h1" as="h1" margin="0 0 x-small">
                  {I18n.t('Course Accessibility Checker')}
                </Heading>
              </Flex.Item>
              <Flex.Item align="start" overflowX="visible" width={props.flexItemWidth}>
                <Button
                  color="primary"
                  margin="small 0"
                  disabled={scanButtonDisabled}
                  onClick={handleCourseScan}
                  display={props.buttonDisplay}
                  width={props.buttonWidth}
                >
                  {I18n.t('Scan Course')}
                </Button>
              </Flex.Item>
            </Flex>
          )
        }}
      />
      {children}
    </View>
  )
}
