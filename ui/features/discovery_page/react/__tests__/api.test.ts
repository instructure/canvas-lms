/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {toCardConfig} from '../api'
import type {DiscoveryConfig} from '../types'

const makeConfig = (primaryLabel: string, secondaryLabel?: string): DiscoveryConfig => ({
  discovery_page: {
    active: true,
    primary: [{authentication_provider_id: 1, label: primaryLabel}],
    secondary: secondaryLabel ? [{authentication_provider_id: 2, label: secondaryLabel}] : [],
  },
})

describe('toCardConfig', () => {
  describe('label HTML decoding', () => {
    it('decodes HTML-encoded ampersands from server', () => {
      const result = toCardConfig(makeConfig('Arts &amp; Sciences'))
      expect(result.discovery_page.primary[0].label).toBe('Arts & Sciences')
    })

    it('decodes HTML-encoded angle brackets from server', () => {
      const result = toCardConfig(makeConfig('Student &lt;-&gt; Teacher'))
      expect(result.discovery_page.primary[0].label).toBe('Student <-> Teacher')
    })

    it('decodes labels in both primary and secondary sections', () => {
      const result = toCardConfig(makeConfig('Arts &amp; Sciences', 'Foo &amp; Bar'))
      expect(result.discovery_page.primary[0].label).toBe('Arts & Sciences')
      expect(result.discovery_page.secondary[0].label).toBe('Foo & Bar')
    })

    it('leaves plain text labels unchanged', () => {
      const result = toCardConfig(makeConfig('Students'))
      expect(result.discovery_page.primary[0].label).toBe('Students')
    })
  })
})
