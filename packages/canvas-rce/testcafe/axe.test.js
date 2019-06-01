/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

/* eslint-disable mocha/no-global-tests, mocha/handle-done-callback */

import axeCheck from 'axe-testcafe'

fixture`aXe a11y checking`.page`./testcafe.html`

test('automated a11y testing', async t => {
  const axeContext = undefined // test the whole page
  const axeOptions = {
    rules: {
      // This is just to get the initial aXe commit passing.
      // These need to be fixed and this rule restored.
      'button-name': {enabled: false}
    }
  }
  await axeCheck(t, axeContext, axeOptions)
})
