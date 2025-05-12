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

import MutexManager from '@canvas/mutex-manager/MutexManager'

/* This mutex ensures tool iframes are not loaded until the
 * DrawerLayout has finished reparenting the application body.
 */
const drawerLayoutMutex = window.ENV.INIT_DRAWER_LAYOUT_MUTEX
const topNavigationTools = document.getElementById('top-nav-tools-mount-point')
const drawerLayout = document.getElementById('drawer-layout-mount-point')

if (drawerLayoutMutex && topNavigationTools && drawerLayout) {
  MutexManager.createMutex(drawerLayoutMutex)
}
