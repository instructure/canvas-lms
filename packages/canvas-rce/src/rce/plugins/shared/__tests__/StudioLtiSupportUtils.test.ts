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

import {studioAttributesFrom, StudioContentItemCustomJson} from '../StudioLtiSupportUtils'

describe('studioAttributesFrom', () => {
  it('uses the default values for missing attributes', () => {
    const customJson: StudioContentItemCustomJson = {source: 'studio'}
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": false,
        "data-studio-tray-enabled": false,
      }
    `)
  })

  it('parses the correct attribute values when they are passed', () => {
    let customJson: StudioContentItemCustomJson = {
      source: 'studio',
      enableMediaOptions: true,
      resizable: true,
    }
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": true,
        "data-studio-tray-enabled": true,
      }
    `)

    customJson = {
      source: 'studio',
      enableMediaOptions: false,
      resizable: false,
    }
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": false,
        "data-studio-tray-enabled": false,
      }
    `)
  })
})
