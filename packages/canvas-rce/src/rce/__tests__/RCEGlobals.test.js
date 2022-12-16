/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import RCEGlobals from '../RCEGlobals'

describe('RCEGlobals', () => {
  describe('features', () => {
    const initialFeatures = {
      feature_1: true,
      feature_2: true,
    }

    const otherFeatures = {some_other_feature: true}

    beforeAll(() => {
      RCEGlobals.setFeatures(initialFeatures)
      RCEGlobals.setFeatures(otherFeatures)
    })

    it('sets the global features exactly once', () => {
      expect(RCEGlobals._data.features).toEqual(initialFeatures)
    })

    it('returns the features', () => {
      expect(RCEGlobals.getFeatures()).toMatchObject(initialFeatures)
    })

    it('does not allow modfication of features directly', () => {
      expect(() => {
        RCEGlobals._data.features.another_feature = false
      }).toThrow(/object is not extensible/)
    })
  })

  describe('config', () => {
    const initialConfig = {
      locale: 'en',
      timezone: 'America/Denver',
    }

    const otherConfig = {somethingElse: true}

    beforeAll(() => {
      RCEGlobals.setConfig(initialConfig)
      RCEGlobals.setConfig(otherConfig)
    })

    it('sets the global config exactly once', () => {
      expect(RCEGlobals._data.config).toEqual(initialConfig)
    })

    it('returns the config', () => {
      expect(RCEGlobals.getConfig()).toMatchObject(initialConfig)
    })

    it('does not allow modfication of config directly', () => {
      expect(() => {
        RCEGlobals._data.config.more_config = 'abcdefg'
      }).toThrow(/object is not extensible/)
    })
  })
})
