/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Table from '@instructure/ui-core/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKey from './DeveloperKey'

class DeveloperKeysTable extends React.Component {
  focusLastDeveloperKey () {
    const developerKeyId = this.props.developerKeysList[this.props.developerKeysList.length - 1].id
    const ref = this[`developerKey-${developerKeyId}`]
    ref.focusDeleteLink()
  }

  render () {
    return (
      <div>
        <Table caption={<ScreenReaderContent>Developer Keys Table</ScreenReaderContent>} id="keys">
        <thead>
          <tr>
            <th scope="col">Name</th>
            <th scope="col">User</th>
            <th scope="col">Details</th>
            <th scope="col">Stats</th>
            <th scope="col" />
          </tr>
        </thead>
        <tbody id="tbody-id">
        {this.props.developerKeysList.map(developerKey => (
          <DeveloperKey
            ref={(key) => {this[`developerKey-${developerKey.id}`] = key}}
            key={developerKey.id}
            developerKey={developerKey}
            store={this.props.store}
            actions={this.props.actions}
          />
        ))}
        </tbody>
      </Table>
      </div>
    )
  }
};

DeveloperKeysTable.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
  }).isRequired,
  developerKeysList: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired
};

export default DeveloperKeysTable
