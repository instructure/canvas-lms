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

import { pickPreferredIntegration } from '../pickPreferredIntegration'
import type {Lti} from '../../models/Product'

describe('pickPreferredIntegration returns expected LTI 1.3 configuration based on payload', () => {
    it('returns LTI 1.3 dynamic registration configuration', () => {
        const payload1: Lti[] = [
              {
                id: 12,
                integration_type: 'lti_13_dynamic_registration',
                description: 'description',
                lti_placements: ['dr'],
                lti_services: ['gk'],
                url: 'google.com',
                unified_tool_id: '1234',
              },
              {
                id: 13,
                integration_type: 'lti_13_global_inherited_key',
                description: 'description2',
                lti_placements: ['dr2'],
                lti_services: ['gk2'],
                global_inherited_key: 'key',
                unified_tool_id: '5678',
              },
            ]
        const result = pickPreferredIntegration(payload1)
        expect(result?.id).toEqual(payload1[0].id)
    })

    it('returns LTI 1.3 global inherited key configuration', () => {
      const payload2: Lti[] = [
            {
              id: 14,
              integration_type: 'lti_13_configuration',
              description: 'description',
              lti_placements: ['dr'],
              lti_services: ['gk'],
              url: '',
              configuration: 'config',
              unified_tool_id: '1234',
            },
            {
              id: 15,
              integration_type: 'lti_13_global_inherited_key',
              description: 'description2',
              lti_placements: ['dr2'],
              lti_services: ['gk2'],
              global_inherited_key: 'key',
              unified_tool_id: '5678',
            },
          ]
      const result = pickPreferredIntegration(payload2)
      expect(result?.id).toEqual(payload2[1].id)
    })

    it('returns LTI 1.3 paste JSON configuration', () => {

      const JSONobj = {
        "name": "Jane Doe",
        "favorite-game": "Stardew Valley",
        "subscriber": false
      }

      const payload3: Lti[] = [
            {
              id: 14,
              integration_type: 'lti_13_configuration',
              description: 'description',
              lti_placements: ['dr'],
              lti_services: ['gk'],
              configuration: JSON.stringify(JSONobj),
              unified_tool_id: '1234',
            },
            {
              id: 15,
              integration_type: 'lti_13_url',
              description: 'description2',
              lti_placements: ['dr2'],
              lti_services: ['gk2'],
              url: 'google.com',
              unified_tool_id: '5678',
            },
          ]
      const result = pickPreferredIntegration(payload3)
      expect(result?.id).toEqual(payload3[0].id)
    })

    it('returns undefined for an LTI 1.1 configuration', () => {
      const payload4: Lti[] = [
            {
              id: 16,
              integration_type: 'lti_11_url',
              description: 'description',
              lti_placements: ['dr'],
              lti_services: ['gk'],
              url: 'google.com',
              unified_tool_id: '1234',
            },
          ]
      const result = pickPreferredIntegration(payload4)
      expect(result).toEqual(undefined)
    })
})