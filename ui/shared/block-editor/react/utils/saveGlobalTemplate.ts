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

import {type BlockTemplate} from '../types'

type Template = Partial<BlockTemplate>

const saveGlobalTemplateToFile = (template: Template) => {
  const blob = new Blob([JSON.stringify(template, null, 2)], {type: 'application/json'})

  const link = document.createElement('a')
  link.setAttribute('style', 'postion: absolute; top: -10000px; left: -10000px')
  link.href = window.URL.createObjectURL(blob)
  link.download = `template-${template.global_id}.json`
  document.body.appendChild(link)
  link.click()
  link.remove()
}

export {saveGlobalTemplateToFile}
