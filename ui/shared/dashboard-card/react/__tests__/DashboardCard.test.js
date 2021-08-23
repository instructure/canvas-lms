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

import DashboardCard, {DashboardCardHeaderHero} from '../DashboardCard'
import React from 'react'
import {render} from '@testing-library/react'

function createMockProps(opts = {}) {
  return {
    shortName: 'foocourse',
    originalName: 'barcourse',
    courseCode: 'FBC',
    assetString: 'foo',
    href: 'courses/1',
    enrollmentType: 'StudentEnrollment',
    ...opts
  }
}

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

  it('renders the observees names when present', () => {
    const props = createMockProps({enrollmentType: 'ObserverEnrollment', observee: 'Student One'})

    const {getByText} = render(<DashboardCard {...props} />)
    expect(getByText(/observing/i)).toBeInTheDocument()
  })

  it('does not render the observee text when not observing', () => {
    const props = createMockProps()

    const {queryByText} = render(<DashboardCard {...props} />)

    expect(queryByText(/observing/i)).not.toBeInTheDocument()
  })
})

describe('PublishButton', () => {
    it('renders the button for users that have the permission', () => {
      const props = createMockProps({
        published: false,
        canChangeCoursePublishState: true,
        pagesUrl: '',
        defaultView: ''
      })
      const {queryByText} = render(<DashboardCard {...props} />)
      expect(queryByText(/Publish/i)).toBeInTheDocument()
    })

    it('does not render the button for users that do not have the permission', () => {
      const props = createMockProps({
        published: false,
        canChangeCoursePublishState: false,
        pagesUrl: '',
        defaultView: ''
      })
      const {queryByText} = render(<DashboardCard {...props} />)
      expect(queryByText(/Publish/i)).not.toBeInTheDocument()
    })
})
