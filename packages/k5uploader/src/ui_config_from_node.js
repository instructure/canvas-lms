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

import UiConfig from './ui_config'
import filterFromNode from './filter_from_node'

export default function (xml) {
  const limits = xml.querySelector('limits')

  const config = new UiConfig({
    maxUploads: limits.getAttribute('maxUploads'),
    maxFileSize: limits.getAttribute('maxFileSize'),
    maxTotalSize: limits.getAttribute('maxTotalSize'),
  })

  const filters = xml.querySelectorAll('fileFilter')

  for (let i = 0, l = filters.length; i < l; i++) {
    const filter = filterFromNode(filters[i])
    config.addFileFilter(filter)
  }
  return config
}
