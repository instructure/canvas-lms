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

import OutcomeCollection from '../../../backbone/collections/OutcomeCollection'

// for working with State Standards in the import dialog
export default class StateStandardsDirectoryView extends OutcomesDirectoryView {
  initialize(_opts) {
    this.outcomes = new OutcomeCollection() // empty - not needed
    return super.initialize(...arguments)
  }

  // don't fetch outcomes

  fetchOutcomes() {}
}
