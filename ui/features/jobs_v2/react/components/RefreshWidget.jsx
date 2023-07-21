/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Spinner} from '@instructure/ui-spinner'
import {IconButton} from '@instructure/ui-buttons'
import {IconRefreshLine} from '@instructure/ui-icons'

const I18n = useI18nScope('jobs_v2')

export default function RefreshWidget({loading, autoRefresh, onRefresh, title}) {
  if (loading) {
    return <Spinner size="x-small" margin="0 0 xx-small xx-small" renderTitle={title} />
  } else if (autoRefresh) {
    return null
  } else {
    return (
      <IconButton
        withBackground={false}
        withBorder={false}
        color="secondary"
        screenReaderLabel={I18n.t('Refresh')}
        onClick={onRefresh}
      >
        <IconRefreshLine />
      </IconButton>
    )
  }
}
