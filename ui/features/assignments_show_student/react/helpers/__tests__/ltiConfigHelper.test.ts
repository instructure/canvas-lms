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
import {getConfigBasedOnToolId} from '../ltiConfigHelper'

describe('getConfigBasedOnToolId', () => {
  const ENV = {LTI_TOOL_ID: '1'}

  beforeEach(() => {
    window.ENV = {...window.ENV, ...ENV}
  })

  it('should return null if no matching definition_id is found', () => {
    const ltiConfigs = [
      {
        definition_id: '2',
        placements: {assignment_selection: {selection_height: 100, selection_width: 200}},
      },
      {
        definition_id: '3',
        placements: {assignment_selection: {selection_height: 150, selection_width: 250}},
      },
    ]
    expect(getConfigBasedOnToolId(ltiConfigs)).toBeNull()
  })

  it('should return the matching config if definition_id matches ENV.LTI_TOOL_ID', () => {
    const ltiConfigs = [
      {
        definition_id: '1',
        placements: {assignment_selection: {selection_height: 100, selection_width: 200}},
      },
      {
        definition_id: '2',
        placements: {assignment_selection: {selection_height: 150, selection_width: 250}},
      },
    ]
    const result = getConfigBasedOnToolId(ltiConfigs)
    expect(result).toEqual(ltiConfigs[0])
  })
})
