/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import TestUtils from 'react-dom/test-utils'
import CollaborationsNavigation from '../CollaborationsNavigation'

const defaultProps = {
  ltiCollaborators: {ltiCollaboratorsData: [{name: 'A name', id: '1'}]},
}

describe('CollaborationsNavigation', () => {
  it('button hidden if create permission is false', () => {
    ENV.context_asset_string = 'courses_1'
    ENV.CREATE_PERMISSION = false

    const component = TestUtils.renderIntoDocument(<CollaborationsNavigation {...defaultProps} />)
    const num_buttons = TestUtils.scryRenderedDOMComponentsWithClass(
      component,
      'create-collaborations-dropdown'
    )
    expect(num_buttons.length).toEqual(0)
  })
})
