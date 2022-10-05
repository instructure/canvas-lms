/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('groups')

const GroupCategoryProgress = props => {
  return (
    <Flex justifyItems="center">
      <Flex.Item>
        <Flex height="400px" width="400px" as="div" direction="column" textAlign="center">
          <Flex.Item margin="medium 0">
            <ProgressBar
              label={I18n.t('Percent complete')}
              size="large"
              formatValueText={() =>
                I18n.t('%{progress} percent', {progress: props.progressPercent})
              }
              formatDisplayedValue={() => (
                <Text size="large" weight="bold">
                  {Math.round(props.progressPercent)}%
                </Text>
              )}
              valueNow={props.progressPercent}
              animateOnMount={true}
            />
          </Flex.Item>
          <Flex.Item>
            <Text size="x-large">{I18n.t('Your groups are being created.')}</Text>
          </Flex.Item>
          <Flex.Item margin="small 0">
            <Text>{I18n.t('This may take a few minutes.')}</Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

export default GroupCategoryProgress
