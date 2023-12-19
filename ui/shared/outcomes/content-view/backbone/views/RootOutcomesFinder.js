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

import OutcomeGroup from '../../../backbone/models/OutcomeGroup'
import splitAssetString from '@canvas/util/splitAssetString'

function RootOutcomesFinder() {}

RootOutcomesFinder.prototype.find = function () {
  // purposely sharing these across instances of RootOutcomesFinder
  let contextOutcomeGroups
  contextOutcomeGroups = null
  const contextTypeAndId = splitAssetString(ENV.context_asset_string || '')
  contextOutcomeGroups = new OutcomeGroup()
  contextOutcomeGroups.url =
    '/api/v1/' + contextTypeAndId[0] + '/' + contextTypeAndId[1] + '/root_outcome_group'
  contextOutcomeGroups.fetch()
  return [contextOutcomeGroups]
}

export default RootOutcomesFinder
