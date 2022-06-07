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
import {axeCheck, createReport} from 'axe-testcafe'
// eslint-disable-next-line babel/no-unused-expressions
fixture`aXe a11y checking`.page`./testcafe.html`

async function runAxeCheck(t, context, options) {
  const {violations} = await axeCheck(t, context, options)
  if (violations) {
    await t.expect(violations.length === 0).ok(createReport(violations))
  }
}

test('automated a11y testing', async t => {
  const axeContext = {
    include: 'body'
  }
  const axeOptions = {
    runOnly: {
      type: 'tag',
      values: ['wcag21a', 'wcag21aa', 'best-practice', 'section508']
    }
  }
  await runAxeCheck(t, axeContext, axeOptions)
})
