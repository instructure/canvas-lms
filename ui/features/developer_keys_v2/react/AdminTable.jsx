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
import {Table} from '@instructure/ui-table'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import React from 'react'
import {arrayOf, func, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import DeveloperKey from './DeveloperKey'

import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('react_developer_keys')

// extracted for shared use by InheritedTable
const createSetFocusCallback =
  ({developerKeysList, developerKeyRef, srMsg, handleRef}) =>
  developerKeys => {
    $.screenReaderFlashMessageExclusive(srMsg)
    const developerKey = developerKeysList
      .concat(developerKeys)
      .reverse()
      .find(key => {
        const keyRef = developerKeyRef(key)
        return keyRef && !keyRef.isDisabled()
      })
    const ref = developerKey ? developerKeyRef(developerKey) : undefined
    handleRef(ref)
    return ref
  }

class AdminTable extends React.Component {
  onDelete = developerKeyId => {
    const {developerKeysList, setFocus} = this.props
    const position = developerKeysList.findIndex(key => key.id === developerKeyId)
    const previousDeveloperKey = developerKeysList[position - 1]
    const ref = previousDeveloperKey ? this.developerKeyRef(previousDeveloperKey) : undefined
    let srMsg
    // If ref is undefined it means that position was -1 and we deleted
    // the first key in the list and focus should go to something other than
    // a dev key
    if (ref === undefined) {
      srMsg = I18n.t(
        'Developer key %{developerKeyId} deleted. Focus moved to add developer key button.',
        {developerKeyId}
      )
      setFocus()
    } else {
      srMsg = I18n.t(
        'Developer key %{developerKeyId} deleted. Focus moved to the delete button of the previous developer key in the list.',
        {developerKeyId}
      )
      ref.focusDeleteLink()
    }
    $.screenReaderFlashMessageExclusive(srMsg)
    return ref
  }

  // this should be called when more keys are loaded,
  // and only handles the screenreader callout
  setFocusCallback = () =>
    createSetFocusCallback({
      developerKeysList: this.props.developerKeysList,
      developerKeyRef: this.developerKeyRef,
      srMsg: I18n.t(
        'Loaded more developer keys. Focus moved to the delete button of the last loaded developer key in the list.'
      ),
      handleRef: ref => ref && ref.focusDeleteLink(),
    })

  developerKeyRef = key => {
    return this[`developerKey-${key.id}`]
  }

  render() {
    const {developerKeysList} = this.props
    const srcontent = I18n.t('Developer Keys')
    return (
      <div>
        <Table
          data-automation="devKeyAdminTable"
          caption={<ScreenReaderContent>{srcontent}</ScreenReaderContent>}
          size="medium"
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="keystable-name">{I18n.t('Name')}</Table.ColHeader>
              <Table.ColHeader id="keystable-owneremail">{I18n.t('Owner Email')}</Table.ColHeader>
              <Table.ColHeader id="keystable-details">{I18n.t('Details')}</Table.ColHeader>
              <Table.ColHeader id="keystable-stats">{I18n.t('Stats')}</Table.ColHeader>
              <Table.ColHeader id="keystable-type">{I18n.t('Type')}</Table.ColHeader>
              <Table.ColHeader id="keystable-state">{I18n.t('State')}</Table.ColHeader>
              <Table.ColHeader id="keystable-actions">{I18n.t('Actions')}</Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {developerKeysList.map(developerKey => (
              <DeveloperKey
                ref={key => {
                  this[`developerKey-${developerKey.id}`] = key
                }}
                key={developerKey.id}
                developerKey={developerKey}
                store={this.props.store}
                actions={this.props.actions}
                ctx={this.props.ctx}
                inherited={false}
                onDelete={this.onDelete}
              />
            ))}
          </Table.Body>
        </Table>
        {developerKeysList.length === 0 && (
          <View as="div" margin="medium" textAlign="center">
            <Text size="large">{I18n.t('Nothing here yet')}</Text>
          </View>
        )}
      </div>
    )
  }
}

AdminTable.propTypes = {
  store: shape({
    dispatch: func.isRequired,
  }).isRequired,
  actions: shape({}).isRequired,
  developerKeysList: arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
  ctx: shape({
    params: shape({
      contextId: string.isRequired,
    }),
  }).isRequired,
  setFocus: func,
}

AdminTable.defaultProps = {setFocus: () => {}}

export default AdminTable
export {createSetFocusCallback}
