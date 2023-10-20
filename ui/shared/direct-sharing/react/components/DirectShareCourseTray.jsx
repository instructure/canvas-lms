/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, {lazy} from 'react'
import CanvasLazyTray from '@canvas/trays/react/LazyTray'

const I18n = useI18nScope('direct_share_course_tray')

const DirectShareCoursePanel = lazy(() => import('./DirectShareCoursePanel'))

export default function DirectShareCourseTray({
  sourceCourseId,
  contentSelection,
  onDismiss,
  ...trayProps
}) {
  return (
    <CanvasLazyTray
      label={I18n.t('Copy To...')}
      placement="end"
      onDismiss={onDismiss}
      padding="medium"
      {...trayProps}
    >
      <DirectShareCoursePanel
        sourceCourseId={sourceCourseId}
        contentSelection={contentSelection}
        onCancel={onDismiss}
      />
    </CanvasLazyTray>
  )
}
