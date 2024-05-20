/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {createAnalyticPropsGenerator} from './util/analytics'
import {MODULE_NAME, TOOLTIP_MAX_WIDTH} from './types'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  testId?: string
}

export default function RoleMismatchToolTip(props: Props) {
  const tipText = (
    <View as="div" textAlign="center" maxWidth={TOOLTIP_MAX_WIDTH}>
      <Text size="small">
        {I18n.t(
          'Enrolling the recipient in these courses will grant them different permissions from the provider of the enrollments'
        )}
      </Text>
    </View>
  )

  const tipTriggers: Array<'click' | 'hover' | 'focus'> = ['click', 'hover', 'focus']
  const renderToolTip = () => {
    return (
      <Tooltip renderTip={tipText} on={tipTriggers} placement="top">
        <IconButton
          renderIcon={IconInfoLine}
          size="small"
          margin="none"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Toggle tooltip')}
          data-testid={props.testId}
          {...analyticProps('Tooltip')}
        />
      </Tooltip>
    )
  }

  return renderToolTip()
}
