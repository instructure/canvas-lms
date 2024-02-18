/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

const I18n = useI18nScope('faculty_journal')

const DeprecationAlert = ({
  deprecationDate,
  timezone,
}: {
  deprecationDate: string
  timezone: string
}) => {
  const dateFormatter = useDateTimeFormat('date.formats.long', timezone)
  return (
    <View as="div" margin="0 0 medium">
      <Alert variant="warning">
        <ScreenReaderContent>
          <Heading level="h2">{I18n.t('Faculty Journal Deprecation')}</Heading>
        </ScreenReaderContent>
        {I18n.t('Faculty Journal will be discontinued on %{deprecationDate}.', {
          deprecationDate: dateFormatter(deprecationDate),
        })}
      </Alert>
    </View>
  )
}

export default DeprecationAlert
