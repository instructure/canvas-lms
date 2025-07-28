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
import {Portal} from '@instructure/ui-portal'
import TopNav, {type ITopNavProps} from './TopNav'
import type {ItemChild} from '@instructure/ui-top-nav-bar/types/TopNavBar/props'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

export type Crumb = Exclude<EnvCommon['breadcrumbs'], undefined>[number]

export interface WithProps extends ITopNavProps {
  actionItems?: ItemChild[]
  currentPageName?: string
  useStudentView?: boolean
  courseId?: number
}

export const getMountPoint = (): HTMLElement | null =>
  document.getElementById('react-instui-topnav')

export const TopNavPortalBase: React.FC<ITopNavProps> = props => {
  const mountPoint = getMountPoint()
  if (!mountPoint) {
    return null
  }

  return (
    <Portal open={true} mountNode={mountPoint}>
      <QueryClientProvider client={queryClient}>
        <TopNav {...props} />
      </QueryClientProvider>
    </Portal>
  )
}

export default TopNavPortalBase
