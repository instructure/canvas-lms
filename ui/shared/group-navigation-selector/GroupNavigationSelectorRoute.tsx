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
import {Portal} from '@instructure/ui-portal'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('group-navigation-selector')

const GroupNavigationSelector = React.lazy(() => import('./GroupNavigationSelector'))

export default function GroupNavigationSelectorRoute() {
  const groupSwitchMountPoint: HTMLElement | null = document.querySelector(
    '#group-switch-mount-point'
  )
  if (!groupSwitchMountPoint) {
    return null
  }

  return (
    <React.Suspense
      fallback={
        <Spinner renderTitle={() => <Spinner renderTitle={I18n.t('Loading')} size="x-small" />} />
      }
    >
      <Portal open={true} mountNode={groupSwitchMountPoint}>
        <GroupNavigationSelector options={ENV.group_information || []} />
      </Portal>
    </React.Suspense>
  )
}
