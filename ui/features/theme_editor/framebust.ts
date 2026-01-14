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

import {PREVIEW_IFRAME_ID} from './react/ThemeEditor'

/**
 * Check if the theme editor should framebust out of an iframe.
 * This prevents theme editor from being loaded inside its own preview iframe.
 * But allows legitimate iframe embedding (e.g., from Horizon).
 */
export function checkShouldFramebust(): boolean {
  const isInIframe = window.top !== window.self
  if (!isInIframe) return false

  try {
    // Check if parent window has the theme editor's preview iframe
    // If it does, we're being loaded inside a theme editor and should framebust
    return window.parent.document.getElementById(PREVIEW_IFRAME_ID) !== null
  } catch (_e) {
    // Cross-origin, can't check - assume not in preview
    return false
  }
}
