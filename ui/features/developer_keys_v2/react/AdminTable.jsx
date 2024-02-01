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
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import React from 'react'
import {arrayOf, func, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import DeveloperKey from './DeveloperKey'
import DeveloperKeyModalTrigger from './NewKeyTrigger'

import '@canvas/rails-flash-notifications'
import FilterBar from '@canvas/filter-bar'
import {Flex} from '@instructure/ui-flex'

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
  constructor(props) {
    super(props)
    this.state = {
      sortBy: 'keystable-details',
      sortAscending: false,
      typeFilter: 'all',
      searchQuery: '',
      sortFlagEnabled: window.ENV?.FEATURES?.enhanced_developer_keys_tables,
    }
  }

  headers = {
    'keystable-name': {
      id: 'keystable-name',
      text: I18n.t('Name'),
      sortable: true,
      sortText: I18n.t('Sort by Name'),
      sortValue: key => key.name,
    },
    'keystable-owneremail': {
      id: 'keystable-owneremail',
      text: I18n.t('Owner Email'),
      sortable: true,
      sortText: I18n.t('Sort by Email'),
      sortValue: key => key.email,
    },
    'keystable-details': {
      id: 'keystable-details',
      text: I18n.t('Details'),
      sortable: true,
      sortText: I18n.t('Sort by Client ID'),
      sortValue: key => key.id,
    },
    'keystable-stats': {
      id: 'keystable-stats',
      text: I18n.t('Stats'),
      sortable: true,
      sortText: I18n.t('Sort by Access Token count'),
      sortValue: key => key.access_token_count,
    },
    'keystable-type': {
      id: 'keystable-type',
      text: I18n.t('Type'),
      sortable: true,
      sortText: I18n.t('Sort by Type'),
      sortValue: key => key.is_lti_key,
    },
    'keystable-state': {
      id: 'keystable-state',
      text: I18n.t('State'),
      sortable: true,
      sortText: I18n.t('Sort by State'),
      sortValue: key => key.developer_key_account_binding.workflow_state,
    },
    'keystable-actions': {
      id: 'keystable-actions',
      text: I18n.t('Actions'),
      sortable: false,
    },
  }

  onRequestSort = (_, {id}) => {
    const {sortBy, sortAscending} = this.state

    if (id === sortBy) {
      this.setState({
        sortAscending: !sortAscending,
      })
    } else {
      this.setState({
        sortBy: id,
        sortAscending: true,
      })
    }
  }

  renderHeader = () => {
    const {sortBy, sortAscending, sortFlagEnabled} = this.state
    const direction = sortAscending ? 'ascending' : 'descending'

    return (
      <Table.Row>
        {Object.values(this.headers).map(header => (
          <Table.ColHeader
            key={header.id}
            id={header.id}
            {...(header.sortable &&
              sortFlagEnabled && {
                sortDirection: sortBy === header.id ? direction : 'none',
                onRequestSort: this.onRequestSort,
              })}
          >
            {header.sortText && sortFlagEnabled ? (
              <Tooltip renderTip={header.sortText} placement="top">
                {header.text}
              </Tooltip>
            ) : (
              header.text
            )}
          </Table.ColHeader>
        ))}
      </Table.Row>
    )
  }

  sortedDeveloperKeys = () => {
    const {sortBy, sortAscending, sortFlagEnabled} = this.state

    if (!sortFlagEnabled) {
      return this.props.developerKeysList
    }

    return this.filteredDeveloperKeys().sort((a, b) => {
      const aVal = this.headers[sortBy].sortValue(a)
      const bVal = this.headers[sortBy].sortValue(b)
      if (aVal < bVal) {
        return sortAscending ? -1 : 1
      }
      if (aVal > bVal) {
        return sortAscending ? 1 : -1
      }
      return 0
    })
  }

  filteredDeveloperKeys = () => {
    const {typeFilter, searchQuery, sortFlagEnabled} = this.state

    if (!sortFlagEnabled) {
      return this.props.developerKeysList
    }

    return this.props.developerKeysList.filter(key => {
      const keyType = key.is_lti_key ? 'lti' : 'api'
      const typeMatch = typeFilter === 'all' || typeFilter === keyType
      const searchMatch =
        searchQuery === '' ||
        this.checkForMatch(key.name, searchQuery) ||
        this.checkForMatch(key.email, searchQuery) ||
        this.checkForMatch(key.id, searchQuery)
      return typeMatch && searchMatch
    })
  }

  checkForMatch = (attr, searchQuery) => {
    return attr && attr.toLowerCase().includes(searchQuery.toLowerCase())
  }

  onDelete = developerKeyId => {
    const developerKeys = this.sortedDeveloperKeys()
    const position = developerKeys.findIndex(key => key.id === developerKeyId)
    const previousDeveloperKey = developerKeys[position - 1]
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
      this.focusDevKeyButton()
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
      developerKeysList: this.sortedDeveloperKeys(),
      developerKeyRef: this.developerKeyRef,
      srMsg: I18n.t(
        'Loaded more developer keys. Focus moved to the delete button of the last loaded developer key in the list.'
      ),
      handleRef: ref => ref && ref.focusDeleteLink(),
    })

  developerKeyRef = key => {
    return this[`developerKey-${key.id}`]
  }

  setAddKeyButtonRef = node => {
    this.addDevKeyButton = node
  }

  focusDevKeyButton = () => {
    this.addDevKeyButton.focus()
  }

  render() {
    const developerKeys = this.sortedDeveloperKeys()
    const {sortFlagEnabled} = this.state
    const srcontent = I18n.t('Developer Keys')
    return (
      <div>
        <Flex justifyItems="space-between" margin="0" wrap="wrap">
          {sortFlagEnabled ? (
            <FilterBar
              filterOptions={[
                {value: 'lti', text: I18n.t('LTI Keys')},
                {value: 'api', text: I18n.t('API Keys')},
              ]}
              onFilter={typeFilter => this.setState({typeFilter})}
              onSearch={searchQuery => this.setState({searchQuery})}
              searchPlaceholder={I18n.t('Search by name, email, or ID')}
              searchScreenReaderLabel={I18n.t('Search Developer Keys')}
            />
          ) : (
            <div></div>
          )}
          <DeveloperKeyModalTrigger
            store={this.props.store}
            actions={this.props.actions}
            setAddKeyButtonRef={this.setAddKeyButtonRef}
          />
        </Flex>
        <Table
          data-automation="devKeyAdminTable"
          caption={<ScreenReaderContent>{srcontent}</ScreenReaderContent>}
          size="medium"
        >
          <Table.Head
            {...(sortFlagEnabled && {
              renderSortLabel: I18n.t('Sort by'),
            })}
          >
            {this.renderHeader()}
          </Table.Head>
          <Table.Body>
            {developerKeys.map(developerKey => (
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
        {developerKeys.length === 0 && (
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
}

export default AdminTable
export {createSetFocusCallback}
