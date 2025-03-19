/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import type {LtiOverlayVersion} from '../../../../model/LtiOverlayVersion'
import {
  mockLtiOverlayVersion,
  mockRegistrationWithAllInformation,
  mockUser,
} from '../../../manage/__tests__/helpers'
import {renderWithRouter} from '../../__tests__/helpers'
import {ToolHistory} from '../ToolHistory'

describe('ToolHistory', () => {
  it('renders without crashing', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [
        mockLtiOverlayVersion({user: mockUser({overrides: {name: 'Foo Bar Baz'}})}),
      ],
    })
    render(renderWithRouter({child: <ToolHistory />, registration}))

    expect(await screen.findByText('Foo Bar Baz')).toBeInTheDocument()
  })

  it('only renders the 5 most recent overlay versions, even if more are included', async () => {
    const allNames = ['foo', 'bar', 'baz', 'qux', 'quux', 'corge']
    const versions: LtiOverlayVersion[] = allNames.map(name => {
      return mockLtiOverlayVersion({user: mockUser({overrides: {name: name}})})
    })

    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: versions,
    })
    render(renderWithRouter({child: <ToolHistory />, registration}))

    const renderedNames = await screen.findAllByText(new RegExp(allNames.join('|')))

    expect(renderedNames).toHaveLength(5)
    expect(screen.queryByText('corge')).not.toBeInTheDocument()
  })

  it('renders a different message if the overlay was reset', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [mockLtiOverlayVersion({overrides: {caused_by_reset: true}})],
    })
    render(renderWithRouter({child: <ToolHistory />, registration}))

    expect(await screen.findByText('Restored to default')).toBeInTheDocument()
  })

  it('renders Instructure as the name if the change was made by a Site Admin', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [mockLtiOverlayVersion({user: 'Instructure'})],
    })
    render(renderWithRouter({child: <ToolHistory />, registration}))

    expect(await screen.findByText('Instructure')).toBeInTheDocument()
  })
})
