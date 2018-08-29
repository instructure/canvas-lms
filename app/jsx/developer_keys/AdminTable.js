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

import $ from 'jquery'
import Table from '@instructure/ui-elements/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!react_developer_keys'

import DeveloperKey from './DeveloperKey'

import 'compiled/jquery.rails_flash_notifications'

class DeveloperKeysTable extends React.Component {
  createSetFocusCallback = (developerKeyId) => {
    const { developerKeysList, setFocus, inherited } = this.props
    const position = developerKeyId ? (developerKeysList.findIndex((key) => key.id === developerKeyId) - 1) : undefined
    const devKey = developerKeysList[position]
    let ref = devKey ? this.developerKeyRef(devKey) : undefined
    // developerKeys will be populated when show more keys is resolved
    return (developerKeys) => {
      // if position is undefined it means that we are loading more keys
      // and we want to calculate the end of the list after the promise
      // resolves
      if (position === undefined) {
        const reversedList = developerKeysList.concat(developerKeys).reverse()
        const developerKey = reversedList.find((key) => {
          const component = this.developerKeyRef(key)
          return !component.isDisabled()
        })
        ref = developerKey ? this.developerKeyRef(developerKey) : undefined
      }
      let srMsg
      // If ref is undefined it means that position was -1 and we deleted
      // the first key in the list and focus should go to something other than
      // a dev key
      if (ref === undefined) {
        // When INSTUI-1202 is completed and the fix in canvas this should be used
        // when inherited keys are loaded
        srMsg = I18n.t("Developer key %{developerKeyId} deleted. Focus moved to add developer key button.", {developerKeyId})
        setFocus()
      } else if (inherited) {
        srMsg = I18n.t("Loaded more developer keys. Focus moved to the name of the last loaded developer key in the list.")
        if (ref) { ref.focusToggleGroup() }
      } else {
        if (position === undefined) {
          srMsg = I18n.t("Loaded more developer keys. Focus moved to the delete button of the last loaded developer key in the list.")
        } else {
          srMsg = I18n.t("Developer key %{developerKeyId} deleted. Focus moved to the delete button of the previous developer key in the list.", {developerKeyId})
        }
        ref.focusDeleteLink()
      }
      $.screenReaderFlashMessageExclusive(srMsg);
      return ref
    }
  }

  developerKeyRef(key) {
    return this[`developerKey-${key.id}`]
  }

  render() {
    const {inherited, developerKeysList} = this.props
    if (developerKeysList.length === 0) {
      return null
    }
    let srcontent = I18n.t('Developers Keys Table')
    if (inherited) {
      srcontent = I18n.t('Inherited Developer Keys Table')
    }
    return (
      <div>
        <Table
          data-automation="devKeyAdminTable"
          caption={<ScreenReaderContent>{srcontent}</ScreenReaderContent>}
          size="medium"
        >
        <thead>
          <tr>
            <th scope="col">{I18n.t('Name')}</th>
            {!inherited && <th scope="col">{I18n.t('Owner Email')}</th> }
            <th scope="col">{I18n.t('Details')}</th>
            {!inherited && <th scope="col">{I18n.t('Stats')}</th>}
            <th scope="col">{I18n.t('State')}</th>
            {!inherited &&  <th scope="col">{I18n.t('Actions')}</th>}
          </tr>
        </thead>
        <tbody>
          {
            this.props.developerKeysList.map((developerKey) => (
              <DeveloperKey
                ref={key => {
                  this[`developerKey-${developerKey.id}`] = key
                }}
                key={developerKey.id}
                developerKey={developerKey}
                store={this.props.store}
                actions={this.props.actions}
                ctx={this.props.ctx}
                inherited={this.props.inherited}
                onDelete={this.createSetFocusCallback}
              />
            ))}
          </tbody>
        </Table>
      </div>
    )
  }
}

DeveloperKeysTable.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired
  }).isRequired,
  actions: PropTypes.shape({}).isRequired,
  developerKeysList: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired,
  inherited: PropTypes.bool,
  setFocus: PropTypes.func
};

DeveloperKeysTable.defaultProps = { inherited: false, setFocus: () => {} }

export default DeveloperKeysTable
