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

// @ts-nocheck

import * as screen from './fake_queries'

describe('fake', () => {
  it('getByRole', () => {
    screen.getByRole('somethingFake')
  })

  it('findByRole', () => {
    screen.findByRole('somethingFake')
  })

  it('queryByRole', () => {
    screen.queryByRole('somethingFake')
  })

  it('getAllByRole', () => {
    screen.getAllByRole('somethingFake')
  })

  it('findAllByRole', () => {
    screen.findAllByRole('somethingFake')
  })

  it('queryAllByRole', () => {
    screen.queryAllByRole('somethingFake')
  })
})
