// @ts-nocheck
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

import canvas from '@instructure/canvas-theme'
import canvasHighContrast from '@instructure/canvas-high-contrast-theme'

import {TreeBrowser} from '@instructure/ui-tree-browser'
import {View} from '@instructure/ui-view'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Node: TreeBrowserNode, Button: TreeBrowserButton} = TreeBrowser as any

const {variables} = ENV.use_high_contrast ? canvasHighContrast : canvas
const {colors} = variables

// Note: there are a few more style overrides set in account_calendar_settings.scss

export const treeBrowserTheme = {
  [TreeBrowserNode.theme]: {
    hoverBackgroundColor: colors.backgroundLight,
    nameTextColor: colors.textDarkest,
    hoverTextColor: colors.textDarkest,
    baseSpacingMedium: '2rem',
  },
  [TreeBrowserButton.theme]: {
    hoverBackgroundColor: colors.backgroundLight,
    nameTextColor: colors.textDarkest,
    hoverTextColor: colors.textDarkest,
    baseSpacingMedium: '2rem',
    nameFontSizeMedium: '1rem',
    focusOutlineStyle: 'none',
  },
}
export const accountListTheme = {
  [View.theme]: {
    borderColorPrimary: colors.porcelain,
  },
}
