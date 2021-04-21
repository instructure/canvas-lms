/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import ObjectStore from './ObjectStore'

class FileStore extends ObjectStore {
  /**
   * contextAndId should be in the format 'context/id'
   * Options is an object containing additional options for the store:
   *    - perPage - indicates the number of records that should be pulled per
   *                request.
   */
  constructor(contextAndId, options) {
    const apiUrl = '/api/v1/' + contextAndId + '/files'
    super(apiUrl, options)
  }
}

export default FileStore
