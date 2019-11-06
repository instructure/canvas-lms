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

import {DashboardCardHeaderHero} from '../DashboardCard'
import React from 'react'
import {render} from '@testing-library/react'

describe('DashboardCardHeaderHero', () => {
  it('doesnt add instFS query params if it doesnt use an inst-fs url', () => {
    const {container} = render(
      <DashboardCardHeaderHero image="https://example.com/path/to/image.png" />
    )
    expect(
      container.querySelector('.ic-DashboardCard__header_image').style['background-image']
    ).toEqual('url(https://example.com/path/to/image.png)')
  })

  it('adds instFS query params if it does use an inst-fs url', () => {
    const {container} = render(
      <DashboardCardHeaderHero image="https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz" />
    )
    expect(
      container.querySelector('.ic-DashboardCard__header_image').style['background-image']
    ).toEqual(
      'url(https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz&geometry=262x146)'
    )
  })
})
