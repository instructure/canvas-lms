/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

/**
 * This utilty function will take a jQuery node and a module id then
 * mutate the $module node to put the appropriate ids in the related
 * module's content elements.
 */
const setupContentIds = ($module, id) => {
  const newVal = `context_module_content_${id}`
  $module.find('#context_module_content_').attr('id', newVal)
  $module.find('[aria-controls="context_module_content_"]').attr('aria-controls', newVal)
}

export default setupContentIds
