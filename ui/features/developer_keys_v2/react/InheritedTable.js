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

import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import React from 'react'
import {arrayOf, func, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import DeveloperKey from './DeveloperKey'
import {createSetFocusCallback} from './AdminTable'

import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('react_developer_keys')

class InheritedTable extends React.Component {
  // this should be called when more keys are loaded,
  // and only handles the screenreader callout
  setFocusCallback = () =>
    createSetFocusCallback({
      developerKeysList: this.props.developerKeysList,
      developerKeyRef: this.developerKeyRef,
      srMsg: I18n.t(
        'Loaded more developer keys. Focus moved to the name of the last loaded developer key in the list.'
      ),
      handleRef: ref => ref.focusToggleGroup()
    })

  developerKeyRef = key => {
    return this[`developerKey-${key.id}`]
  }

  render() {
    const {developerKeysList} = this.props
    if (developerKeysList.length === 0) {
      return null
    }
    const srcontent = I18n.t('Inherited Developer Keys Table')
    return (
      <div>
        <Table
          data-automation="devKeyInheritedTable"
          caption={<ScreenReaderContent>{srcontent}</ScreenReaderContent>}
          size="medium"
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="keystable-name">{I18n.t('Name')}</Table.ColHeader>
              <Table.ColHeader id="keystable-details">{I18n.t('Details')}</Table.ColHeader>
              <Table.ColHeader id="keystable-type">{I18n.t('Type')}</Table.ColHeader>
              <Table.ColHeader id="keystable-state">{I18n.t('State')}</Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {this.props.developerKeysList.map(developerKey => (
              <DeveloperKey
                ref={key => {
                  this[`developerKey-${developerKey.id}`] = key
                }}
                key={developerKey.id}
                developerKey={developerKey}
                store={this.props.store}
                actions={this.props.actions}
                ctx={this.props.ctx}
                inherited
                // inherited keys can't be deleted
                onDelete={() => {}}
              />
            ))}
          </Table.Body>
        </Table>
      </div>
    )
  }
}

InheritedTable.propTypes = {
  store: shape({
    dispatch: func.isRequired
  }).isRequired,
  actions: shape({}).isRequired,
  developerKeysList: arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
  ctx: shape({
    params: shape({
      contextId: string.isRequired
    })
  }).isRequired
}

export default InheritedTable
