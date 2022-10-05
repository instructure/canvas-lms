/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import router from 'ui/features/files/router'

// No op for next().
const fakeNext = () => {}

QUnit.module('Files Client-side Router')

test('getFolderSplat returns the proper splat on ctx given uri characters', () => {
  const fakeCtx = {
    pathname: '/folder/this#could+be bad? maybe',
  }

  router.getFolderSplat(fakeCtx, fakeNext)

  equal(fakeCtx.splat, 'this%23could%2Bbe%20bad%3F%20maybe', 'splat is correctly encoded')
})

test('getFolderSplat returns the proper splat on ctx with multiple levels', () => {
  const fakeCtx = {
    pathname: '/folder/this#could+be bad? maybe/another?bad folder/something else',
  }

  router.getFolderSplat(fakeCtx, fakeNext)

  equal(
    fakeCtx.splat,
    'this%23could%2Bbe%20bad%3F%20maybe/another%3Fbad%20folder/something%20else',
    'splat is correctly encoded'
  )
})
