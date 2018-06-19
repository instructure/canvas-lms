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

import packageJson from '../../../package.json'

describe('app/stylesheets/components/_canvas-icons.scss', () => {
  it(`
  when we upgrade inst-ui or instructure-icons to a version that does RTL
  flipping for icons automatically, we need to remove the css to flip the from
  app/stylesheets/components/_canvas-icons.scss`
  , () => {
    expect(packageJson.dependencies['@instructure/ui-core']).toBe('^4.8.0')
    expect(packageJson.dependencies['instructure-icons']).toBe('^4')
    /* this test is just here to remind us that if we upgrade either instUI or instructure-icons
       to a version that does the RTL icon arrow flipping for us, we need to remove the
       ```
       // flip all the arrows around in RTL
       @if $direction == 'rtl' {`
       ```
       block in app/stylesheets/components/_canvas-icons.scss.
       Once we do, we can remove that block and this test.
     */
  })
})
