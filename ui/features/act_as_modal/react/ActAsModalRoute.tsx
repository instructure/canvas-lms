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
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Portal} from '@instructure/ui-portal'

const I18n = useI18nScope('act_as')

const ActAsModal = React.lazy(() => import('./ActAsModal'))

export default function GroupNavigationSelectorRoute() {
  const mountPoint: HTMLElement | null = document.querySelector('#act_as_modal')
  if (!mountPoint) {
    return null
  }
  return (
    <React.Suspense
      fallback={
        <Spinner renderTitle={() => <Spinner renderTitle={I18n.t('Loading')} size="x-small" />} />
      }
    >
      <Portal open={true} mountNode={mountPoint}>
        {/* @ts-expect-error */}
        <ActAsModal user={ENV.act_as_user_data.user} />
      </Portal>
    </React.Suspense>
  )
}
