/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * This apolloClient is meant to be used in old pre-React Canvas (for testing
 * React components that use Apollo, see the `MockProvider` in the Apollo
 * docs).
 *
 * see apollo_without_react_spec.js for examples of this module.
 */

import {createClient} from '@canvas/apollo'
import {MockLink} from '@apollo/react-testing'

/*
 * React components should use Apollo's MockProvider instead of MockCanvasClient.
 *
 * Make sure your mocked query/variables exactly match the query/variables your
 * script will issue.
 */

const MockCanvasClient = {
  install: mocks => {
    createClient.mockLink = new MockLink(mocks, true)
  },

  uninstall: () => {
    delete createClient.mockLink
  },
}

export default MockCanvasClient
