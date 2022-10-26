/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import ExternalToolCollection from 'ui/features/submit_assignment/backbone/collections/ExternalToolCollection'

const data = [
  {
    description: 'Embed files from Box.net',
    domain: 'localhost',
    id: '1',
    name: 'Box',
  },
  {
    description: 'This example LTI Tool Provider supports LIS Outcome...',
    domain: 'lti-tool-provider.herokuapp.com',
    id: '2',
    name: "Brad's Tool",
  },
]

QUnit.module('ExternalToolCollection', {
  setup() {
    this.externalToolCollection = new ExternalToolCollection()
    this.externalToolCollection.add(data)
  },
})

test('finds a tool by id', function () {
  const tool = this.externalToolCollection.findWhere({id: '1'})
  equal(tool.get('name'), 'Box')
})
