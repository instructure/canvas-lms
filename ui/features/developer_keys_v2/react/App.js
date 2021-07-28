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

import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'

import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKeysTable from './AdminTable'
import DeveloperKey from './DeveloperKey'
import NewKeyModal from './NewKeyModal'
import DeveloperKeyModalTrigger from './NewKeyTrigger'

class DeveloperKeysApp extends React.Component {
  state = {
    focusTab: false,
    selectedTab: 'tab-panel-account'
  }

  get isSiteAdmin() {
    return this.props.ctx.params.contextId === 'site_admin'
  }

  setMainTableRef = node => {
    this.mainTableRef = node
  }

  setInheritedTableRef = node => {
    this.inheritedTableRef = node
  }

  setAddKeyButtonRef = node => {
    this.addDevKeyButton = node
  }

  setInheritedTabRef = node => {
    this.inheritedTab = node
  }

  focusDevKeyButton = () => {
    this.addDevKeyButton.focus()
  }

  focusInheritedTab = () => {
    this.setState({focusTab: true})
  }

  showMoreButtonHandler = _event => {
    const {
      applicationState: {
        listDeveloperKeys: {nextPage}
      },
      store: {dispatch},
      actions: {getRemainingDeveloperKeys}
    } = this.props
    const callBack = this.mainTableRef.createSetFocusCallback()
    getRemainingDeveloperKeys(nextPage, [], callBack)(dispatch)
  }

  showMoreButton() {
    const {
      applicationState: {
        listDeveloperKeys: {listDeveloperKeysPending, nextPage}
      }
    } = this.props

    if (nextPage && !listDeveloperKeysPending) {
      return <Button onClick={this.showMoreButtonHandler}>{I18n.t('Show All Keys')}</Button>
    }
    return null
  }

  showMoreInheritedButtonHandler = _event => {
    const {
      applicationState: {
        listDeveloperKeys: {inheritedNextPage}
      },
      store: {dispatch},
      actions: {getRemainingInheritedDeveloperKeys}
    } = this.props

    const callBack = this.inheritedTableRef.createSetFocusCallback()
    getRemainingInheritedDeveloperKeys(
      inheritedNextPage,
      [],
      callBack
    )(dispatch).then(foundActiveKey => {
      if (!foundActiveKey) {
        this.focusInheritedTab()
      }
    })
  }

  showMoreInheritedButton() {
    const {
      applicationState: {
        listDeveloperKeys: {listInheritedDeveloperKeysPending, inheritedNextPage}
      }
    } = this.props

    if (inheritedNextPage && !listInheritedDeveloperKeysPending) {
      return (
        <Button onClick={this.showMoreInheritedButtonHandler}>{I18n.t('Show All Keys')}</Button>
      )
    }
    return null
  }

  changeTab(_ev, {id}) {
    this.setState({selectedTab: id})
  }

  render() {
    const {
      applicationState: {
        listDeveloperKeys: {
          list,
          inheritedList,
          listDeveloperKeysPending,
          listInheritedDeveloperKeysPending
        },
        createOrEditDeveloperKey,
        listDeveloperKeyScopes
      },
      store,
      actions,
      ctx
    } = this.props
    const tab = this.state.selectedTab

    return (
      <div>
        <View as="div" margin="0 0 small 0" padding="none">
          <Heading level="h1">{I18n.t('Developer Keys')}</Heading>
        </View>
        <Tabs
          onRequestTabChange={this.changeTab.bind(this)}
          shouldFocusOnRender={this.state.focusTab}
        >
          <Tabs.Panel
            renderTitle={I18n.t('Account')}
            id="tab-panel-account"
            isSelected={tab === 'tab-panel-account'}
          >
            <DeveloperKeyModalTrigger
              store={store}
              actions={actions}
              setAddKeyButtonRef={this.setAddKeyButtonRef}
            />
            <NewKeyModal
              store={store}
              actions={actions}
              createOrEditDeveloperKeyState={createOrEditDeveloperKey}
              availableScopes={listDeveloperKeyScopes.availableScopes}
              availableScopesPending={listDeveloperKeyScopes.listDeveloperKeyScopesPending}
              selectedScopes={listDeveloperKeyScopes.selectedScopes}
              ctx={ctx}
            />
            <DeveloperKeysTable
              ref={this.setMainTableRef}
              store={store}
              actions={actions}
              developerKeysList={list}
              ctx={ctx}
              setFocus={this.focusDevKeyButton}
            />
            <View as="div" margin="small" padding="large" textAlign="center">
              {listDeveloperKeysPending ? <Spinner renderTitle={I18n.t('Loading')} /> : null}
              {this.showMoreButton()}
            </View>
          </Tabs.Panel>
          {this.isSiteAdmin ? null : (
            <Tabs.Panel
              renderTitle={I18n.t('Inherited')}
              elementRef={this.setInheritedTabRef}
              id="tab-panel-inherited"
              isSelected={tab === 'tab-panel-inherited'}
            >
              <DeveloperKeysTable
                ref={this.setInheritedTableRef}
                store={store}
                actions={actions}
                developerKeysList={inheritedList}
                ctx={ctx}
                inherited
                setFocus={this.focusInheritedTab}
              />
              <View as="div" margin="small" padding="large" textAlign="center">
                {listInheritedDeveloperKeysPending ? (
                  <Spinner renderTitle={I18n.t('Loading')} />
                ) : null}
                {this.showMoreInheritedButton()}
              </View>
            </Tabs.Panel>
          )}
        </Tabs>
      </div>
    )
  }
}

DeveloperKeysApp.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired
  }).isRequired,
  actions: PropTypes.shape({
    developerKeysModalOpen: PropTypes.func.isRequired,
    getRemainingDeveloperKeys: PropTypes.func.isRequired,
    getRemainingInheritedDeveloperKeys: PropTypes.func.isRequired,
    editDeveloperKey: PropTypes.func.isRequired
  }).isRequired,
  applicationState: PropTypes.shape({
    createOrEditDeveloperKey: PropTypes.shape({
      developerKeyCreateOrEditFailed: PropTypes.bool.isRequired,
      developerKeyCreateOrEditSuccessful: PropTypes.bool.isRequired
    }),
    listDeveloperKeys: PropTypes.shape({
      nextPage: PropTypes.string,
      listDeveloperKeysPending: PropTypes.bool.isRequired,
      listDeveloperKeysSuccessful: PropTypes.bool.isRequired,
      nextInheritedPage: PropTypes.string,
      listInheritedDeveloperKeysPending: PropTypes.bool.isRequired,
      listInheritedDeveloperKeysSuccessful: PropTypes.bool.isRequired,
      list: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
      inheritedList: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired
    }).isRequired
  }).isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired
}

export default DeveloperKeysApp
