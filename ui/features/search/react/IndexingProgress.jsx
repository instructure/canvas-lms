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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {ProgressBar} from '@instructure/ui-progress'

const I18n = useI18nScope('SmartSearch')

export default function IndexingProgress({progress}) {
  return (
    <div>
      <Text>
        {I18n.t(
          'Please wait a moment while we get Smart Search ready for this course. This only needs to happen once.'
        )}
      </Text>
      <br />
      <Text fontStyle="italic">
        {I18n.t(
          'You can leave this page and come back, and we will keep working in the background.'
        )}
      </Text>
      <ProgressBar
        screenReaderLabel={I18n.t('Indexing in progress')}
        valueNow={progress}
        valueMax={100}
      />
    </div>
  )
}
