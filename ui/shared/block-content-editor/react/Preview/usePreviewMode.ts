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

import {useState} from 'react'

export type PreviewMode = 'desktop' | 'tablet' | 'mobile'

const previewSizes: Record<PreviewMode, {containerWidth: number; contentWidth: number}> = {
  desktop: {containerWidth: 900, contentWidth: 1042},
  tablet: {containerWidth: 600, contentWidth: 768},
  mobile: {containerWidth: 375, contentWidth: 375},
}

export const usePreviewMode = () => {
  const [previewMode, setPreviewMode] = useState<PreviewMode>('desktop')
  return {previewMode, setPreviewMode, ...previewSizes[previewMode]}
}
