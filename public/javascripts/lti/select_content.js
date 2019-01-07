/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export default class {
  static contentPlacements = ['resource_selection']

  static contentMessageTypes = ['ContentItemSelectionRequest', 'LtiDeepLinkingRequest']

  static isContentMessage(placement, placements = {}) {
    const message_type = placement && placement.message_type

    return (
      this.contentPlacements.some(p => Object.keys(placements).includes(p)) ||
      this.contentMessageTypes.includes(message_type)
    )
  }
}
