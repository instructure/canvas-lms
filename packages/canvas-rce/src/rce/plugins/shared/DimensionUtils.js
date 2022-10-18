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

function scaleEvenly(width, height, scaleFactor, constraints) {
  const minHeight = constraints.minHeight || 0
  const minWidth = constraints.minWidth || 0

  const scaledWidth = width * scaleFactor
  const scaledHeight = height * scaleFactor

  let minimumScaleFactor = scaleFactor
  if (scaledWidth < minWidth) {
    const atLeastMinWidth = Math.max(scaledWidth, minWidth)
    minimumScaleFactor = atLeastMinWidth / width
  }

  if (scaledHeight < minHeight) {
    const atLeastMinHeight = Math.max(scaledHeight, minHeight)
    minimumScaleFactor = Math.max(atLeastMinHeight / height, minimumScaleFactor)
  }

  return {
    height: Math.round(height * minimumScaleFactor),
    width: Math.round(width * minimumScaleFactor),
  }
}

export function scaleForHeight(width, height, targetHeight, constraints = {}) {
  if (targetHeight == null) {
    return {height: null, width: null}
  }

  const scaleFactor = targetHeight / height
  return scaleEvenly(width, height, scaleFactor, constraints)
}

export function scaleForWidth(width, height, targetWidth, constraints = {}) {
  if (targetWidth == null) {
    return {height: null, width: null}
  }

  const scaleFactor = targetWidth / width
  return scaleEvenly(width, height, scaleFactor, constraints)
}
