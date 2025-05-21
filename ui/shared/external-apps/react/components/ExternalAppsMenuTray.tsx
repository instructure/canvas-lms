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

import CanvasLazyTray from '@canvas/trays/react/LazyTray'
import {ContentSelection} from '../shared/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import ExternalAppsMenuPanel from './ExternalAppsMenuPanel'

const I18n = createI18nScope('external_apps_menu_tray')

type ExternalAppsMenuTrayProps = {
  sourceCourseId: string
  contentSelection: ContentSelection
  onDismiss: () => void
  moduleId: string
}

export default function ExternalAppsMenuTray({
  sourceCourseId,
  contentSelection,
  onDismiss,
  moduleId,
  ...trayProps
}: ExternalAppsMenuTrayProps) {
  return (
    <CanvasLazyTray
      label={I18n.t('External Apps...')}
      placement="end"
      onDismiss={onDismiss}
      padding="medium"
      {...trayProps}
    >
      <ExternalAppsMenuPanel
        contentSelection={contentSelection}
        onDismiss={onDismiss}
        moduleId={moduleId}
      />
    </CanvasLazyTray>
  )
}
