// @ts-nocheck
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

import shouldUseFeature, {Feature} from '../shouldUseFeature'

describe('shouldUseFeature()', () => {
  let feature: Feature, windowEnv: object

  const getFeature = (): Feature => feature
  const getWindowEnv = (): object => windowEnv
  const subject = (): boolean => shouldUseFeature(getFeature(), getWindowEnv())

  beforeEach(() => (windowEnv = {}))

  const sharedExamplesForFeaturesToDisable = () => {
    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  }

  const sharedExamplesForFeaturesToEnable = () => {
    it('returns true', () => {
      expect(subject()).toEqual(false)
    })
  }

  describe('when the feature is icon maker', () => {
    beforeEach(() => (feature = Feature.IconMaker))

    // This feature was re-named to match the updated name: "Buttons and Icons" => "Icon Maker"
    // But the feature flag was NOT renamed so it's still "buttons_and_icons_root_account"
    describe('and the buttons & icons (icon maker) feature flag is on', () => {
      beforeEach(() => {
        windowEnv.FEATURES = {
          buttons_and_icons_root_account: true,
        }
      })

      describe('and the user has only "add file" permissions', () => {
        beforeEach(() => {
          windowEnv.RICH_CONTENT_CAN_UPLOAD_FILES = true
        })

        sharedExamplesForFeaturesToDisable()
      })

      describe('and the user has only "edit file" permissions', () => {
        beforeEach(() => {
          windowEnv.RICH_CONTENT_CAN_EDIT_FILES = true
        })

        sharedExamplesForFeaturesToDisable()
      })

      describe('and the user has both "add file" and "edit file" permissions', () => {
        beforeEach(() => {
          windowEnv.RICH_CONTENT_CAN_UPLOAD_FILES = true
          windowEnv.RICH_CONTENT_CAN_EDIT_FILES = true
        })

        sharedExamplesForFeaturesToEnable()
      })
    })

    // This feature was re-named to match the updated name: "Buttons and Icons" => "Icon Maker"
    // But the feature flag was NOT renamed so it's still "buttons_and_icons_root_account"
    describe('and the buttons & icons (icon maker) feature flag is off', () => {
      beforeEach(() => {
        windowEnv.FEATURES = {
          buttons_and_icons_root_account: true,
        }
      })

      sharedExamplesForFeaturesToDisable()
    })
  })

  describe('when the feature is not recognized', () => {
    beforeEach(() => (feature = 'banana'))

    sharedExamplesForFeaturesToDisable()
  })
})
