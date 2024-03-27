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
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import AdminTable from './AdminTable'
import InheritedTable from './InheritedTable'
import DeveloperKey from './DeveloperKey'
import NewKeyModal from './NewKeyModal'
import {showFlashAlert, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import DateHelper from '@canvas/datetime/dateHelper'
import {DynamicRegistrationModal} from './dynamic_registration/DynamicRegistrationModal'

const I18n = useI18nScope('react_developer_keys')
/**
 * @see {@link DeveloperKeysApp.developerKeySaveSuccessfulHandler}
 * @description
 * How long to wait after closing NewKeyModal to show any developer key alerts.
 * This value might be able to be decreased, but two seconds is a pretty
 * safe gap.
 */
const ALERT_WAIT_TIME = 2000

class DeveloperKeysApp extends React.Component {
  state = {
    focusTab: false,
    selectedTab: 'tab-panel-account',
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

  setInheritedTabRef = node => {
    this.inheritedTab = node
  }

  focusInheritedTab = () => {
    this.setState({focusTab: true})
  }

  showMoreButtonHandler = _event => {
    const {
      applicationState: {
        listDeveloperKeys: {nextPage},
      },
      store: {dispatch},
      actions: {getRemainingDeveloperKeys},
    } = this.props
    const callBack = this.mainTableRef.setFocusCallback()
    getRemainingDeveloperKeys(nextPage, [], callBack)(dispatch)
  }

  showMoreButton() {
    const {
      applicationState: {
        listDeveloperKeys: {listDeveloperKeysPending, nextPage},
      },
    } = this.props

    if (nextPage && !listDeveloperKeysPending) {
      return <Button onClick={this.showMoreButtonHandler}>{I18n.t('Show All Keys')}</Button>
    }
    return null
  }

  showMoreInheritedButtonHandler = _event => {
    const {
      applicationState: {
        listDeveloperKeys: {inheritedNextPage},
      },
      store: {dispatch},
      actions: {getRemainingInheritedDeveloperKeys},
    } = this.props

    const callBack = this.inheritedTableRef.setFocusCallback()
    getRemainingInheritedDeveloperKeys(inheritedNextPage, [], callBack)(dispatch)
  }

  showMoreInheritedButton() {
    const {
      applicationState: {
        listDeveloperKeys: {listInheritedDeveloperKeysPending, inheritedNextPage},
      },
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

  /**
   * Due to some annoying accessibility issues related to modal focus
   * returning and screenreader issues, we have to use a setTimeout here
   * to make sure either alert gets read out properly. Without a setTimeout,
   * the alert shows up, but because the Modal returns focus back to the element
   * that opened it, the screenreader starts and then immediately stops reading
   * the alert, instead reading out the description of the edit developer key
   * button. If you can find a better solution, please remove this hacky
   * workaround and do it.
   * @todo Find a better way to avoid modal-focus-screenreader-bulldozing so
   * this isn't necessary.
   * @param {string} warningMessage - A warning message to show to the user.
   */
  developerKeySaveSuccessfulHandler(warningMessage) {
    setTimeout(() => {
      showFlashSuccess(I18n.t('Save successful.'))()
      if (warningMessage) {
        showFlashAlert({message: warningMessage, type: 'warning'})
      }
    }, ALERT_WAIT_TIME)
  }

  render() {
    const {
      applicationState: {
        listDeveloperKeys: {
          list,
          inheritedList,
          listDeveloperKeysPending,
          listInheritedDeveloperKeysPending,
        },
        createOrEditDeveloperKey,
        listDeveloperKeyScopes,
      },
      store,
      actions,
      ctx,
    } = this.props
    const tab = this.state.selectedTab
    const globalInheritedList = (inheritedList || []).filter(key => key.inherited_from === 'global')
    const parentInheritedList = (inheritedList || []).filter(
      key => key.inherited_from === 'federated_parent'
    )

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
            <NewKeyModal
              store={store}
              actions={actions}
              createOrEditDeveloperKeyState={createOrEditDeveloperKey}
              availableScopes={listDeveloperKeyScopes.availableScopes}
              availableScopesPending={listDeveloperKeyScopes.listDeveloperKeyScopesPending}
              selectedScopes={listDeveloperKeyScopes.selectedScopes}
              ctx={ctx}
              handleSuccessfulSave={this.developerKeySaveSuccessfulHandler}
            />
            <DynamicRegistrationModal contextId={this.props.ctx.params.contextId} store={store} />
            <AdminTable
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
              {parentInheritedList.length > 0 && (
                <>
                  <Heading margin="small" level="h2">
                    {I18n.t('Consortium Parent Keys')}
                  </Heading>
                  <InheritedTable
                    prefix="parent"
                    label={I18n.t('Parent Inherited Developer Keys')}
                    store={store}
                    actions={actions}
                    developerKeysList={parentInheritedList}
                    ctx={ctx}
                  />
                  <Heading margin="small" level="h2">
                    {I18n.t('Global Keys')}
                  </Heading>
                </>
              )}
              <InheritedTable
                prefix="global"
                label={I18n.t('Global Inherited Developer Keys')}
                ref={this.setInheritedTableRef}
                store={store}
                actions={actions}
                developerKeysList={globalInheritedList}
                ctx={ctx}
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
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    developerKeysModalOpen: PropTypes.func.isRequired,
    getRemainingDeveloperKeys: PropTypes.func.isRequired,
    getRemainingInheritedDeveloperKeys: PropTypes.func.isRequired,
    editDeveloperKey: PropTypes.func.isRequired,
  }).isRequired,
  applicationState: PropTypes.shape({
    createOrEditDeveloperKey: PropTypes.shape({
      developerKeyCreateOrEditFailed: PropTypes.bool.isRequired,
      developerKeyCreateOrEditSuccessful: PropTypes.bool.isRequired,
    }),
    listDeveloperKeys: PropTypes.shape({
      nextPage: PropTypes.string,
      listDeveloperKeysPending: PropTypes.bool.isRequired,
      listDeveloperKeysSuccessful: PropTypes.bool.isRequired,
      nextInheritedPage: PropTypes.string,
      listInheritedDeveloperKeysPending: PropTypes.bool.isRequired,
      listInheritedDeveloperKeysSuccessful: PropTypes.bool.isRequired,
      list: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
      inheritedList: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
    }).isRequired,
  }).isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired,
    }),
  }).isRequired,
}

export default DeveloperKeysApp
