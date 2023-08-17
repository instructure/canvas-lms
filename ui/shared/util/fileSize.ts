/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export default function fileSize(bytes: number): string {
  const factor = 1024
  if (bytes < factor) {
    return `${bytes} bytes`
  } else if (bytes < factor * factor) {
    return `${Math.floor(bytes / factor)}KB`
  } else {
    return `${Math.round((10.0 * bytes) / factor / factor) / 10.0}MB`
  }
}
