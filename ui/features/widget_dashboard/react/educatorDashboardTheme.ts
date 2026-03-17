/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

// Educator dashboard dark navy palette — no InstUI token equivalents exist for these values
const NAVY_DARK = '#061C30'
const NAVY_HOVER = '#0D2D4A'
const NAVY_MID = '#1D354F'
const TAG_BG = '#D5E2F6'
const TAG_TEXT = '#273540'
const WHITE = '#FFFFFF'

export const EDUCATOR_DASHBOARD_THEME = {
  componentOverrides: {
    Button: {
      primaryBackground: NAVY_DARK,
      primaryBorderColor: NAVY_DARK,
      primaryHoverBackground: NAVY_HOVER,
      primaryActiveBackground: NAVY_DARK,
      borderRadius: '12px',
    },
    TextInput: {
      borderRadius: '12px',
    },
    TextArea: {
      borderRadius: '12px',
    },
    Tag: {
      defaultBackground: TAG_BG,
      defaultBorderColor: TAG_BG,
      defaultColor: TAG_TEXT,
      defaultBorderRadius: '8px',
    },
    'Options.Item': {
      selectedBackground: NAVY_MID,
      selectedLabelColor: WHITE,
      selectedHighlightedBackground: NAVY_MID,
    },
    Modal: {
      borderRadius: '12px',
    },
    'Modal.Footer': {
      borderRadius: '12px',
    },
    View: {
      borderRadiusLarge: '12px',
      borderRadiusMedium: '12px',
    },
  },
}
