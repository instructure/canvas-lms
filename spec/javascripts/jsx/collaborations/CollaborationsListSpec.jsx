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

import React from 'react'
import TestUtils from 'react-dom/test-utils'
import CollaborationsList from 'ui/features/lti_collaborations/react/CollaborationsList'

QUnit.module('CollaborationsList')

const collaborations = [
  {
    id: 1,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    permissions: {
      update: true,
      delete: true,
    },
  },
  {
    id: 2,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: new Date(0).toString(),
    permissions: {
      update: true,
      delete: true,
    },
  },
]

const collaborationsState = {
  nextPage: 'www.testurl.com',
  listCollaborationsPending: 'true',
  list: collaborations,
}

test('renders the list of collaborations', () => {
  ENV.context_asset_string = 'courses_1'
  const component = TestUtils.renderIntoDocument(
    <CollaborationsList collaborationsState={collaborationsState} />
  )
  const collaborationComponents = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'Collaboration'
  )
  equal(collaborationComponents.length, 2)
})
