//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import OutcomesDirectoryView from './OutcomesDirectoryView'
import OutcomeCollection from '../../collections/OutcomeCollection'
import OutcomeGroupCollection from '../../collections/OutcomeGroupCollection'

// for working with Account Standards in the import dialog
export default class AccountDirectoryView extends OutcomesDirectoryView {
  initialize(opts) {
    this.outcomes = new OutcomeCollection() // empty - not needed
    this.groups = new OutcomeGroupCollection()
    this.groups.url = ENV.ACCOUNT_CHAIN_URL

    return super.initialize(opts)
  }

  // don't fetch outcomes
  fetchOutcomes() {}
}
