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
import WidgetGrid from './WidgetGrid'
import {useWidgetDashboardEdit} from '../hooks/useWidgetDashboardEdit'
import {useWidgetConfig} from '../hooks/useWidgetConfig'

const DashboardTab: React.FC = () => {
  const {isEditMode} = useWidgetDashboardEdit()
  const {config} = useWidgetConfig()

  return (
    <View as="div" data-testid="dashboard-tab-content" padding="medium 0 0 0">
      <WidgetGrid config={config} isEditMode={isEditMode} />
    </View>
  )
}

export default DashboardTab
