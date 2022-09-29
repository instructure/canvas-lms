/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import ModuleSequenceFooter from '@canvas/module-sequence-footer'

function getContextModuleData(courseID, assignmentID) {
  const instance = new ModuleSequenceFooter({
    assetType: 'Assignment',
    assetID: assignmentID,
    courseID,
  })

  // Calling fetch() will set the data we want on the calling instance, so we
  // return the instance as the resolved value. (fetch() itself returns a
  // jQuery Deferred object, which we wrap in a promise so callers don't have
  // to deal with it.)
  return new Promise((resolve, reject) => {
    // eslint-disable-next-line promise/catch-or-return
    instance.fetch().then(() => resolve(instance), reject)
  })
}

export default {
  getContextModuleData,
}
