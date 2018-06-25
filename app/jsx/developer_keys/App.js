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

import Button from '@instructure/ui-buttons/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import View from '@instructure/ui-layout/lib/components/View'

import IconPlusLine from '@instructure/ui-icons/lib/Line/IconPlus'

import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKeysTable from './AdminTable'
import DeveloperKey from './DeveloperKey'
import DeveloperKeyModal from './NewKeyModal'

class DeveloperKeysApp extends React.Component {
  state = {
    focusTab: false
  }

  get isSiteAdmin() {
    return this.props.ctx.params.contextId === "site_admin"
  }

  setMainTableRef = (node) => { this.mainTableRef = node }
  setInheritedTableRef = (node) => { this.inheritedTableRef = node }
  setAddKeyButtonRef = (node) => { this.addDevKeyButton = node }
  setInheritedTabRef = (node) => { this.inheritedTab = node }

  focusDevKeyButton = () => { this.addDevKeyButton.focus() }
  focusInheritedTab = () => { this.setState({focusTab: true}) }

  showCreateDeveloperKey = () => {
    this.props.store.dispatch(this.props.actions.developerKeysModalOpen())
  }

  showMoreButtonHandler = _event => {
    const {
      applicationState: {listDeveloperKeys: {nextPage}},
      store: {dispatch},
      actions: {getRemainingDeveloperKeys}
    } = this.props
    const callBack = this.mainTableRef.createSetFocusCallback()
    getRemainingDeveloperKeys(nextPage, [], callBack)(dispatch)
  }

  showMoreButton() {
    const {applicationState: {listDeveloperKeys: {listDeveloperKeysPending, nextPage}}} = this.props

    if (nextPage && !listDeveloperKeysPending) {
      return (
        <Button onClick={this.showMoreButtonHandler}>
          {I18n.t("Show All Keys")}
        </Button>)
    }
    return null
  }

  showMoreInheritedButtonHandler = _event => {
    const {
      applicationState: {listDeveloperKeys: {inheritedNextPage}},
      store: {dispatch},
      actions: {getRemainingInheritedDeveloperKeys}
    } = this.props

    const callBack = this.inheritedTableRef.createSetFocusCallback()
    getRemainingInheritedDeveloperKeys(inheritedNextPage, [], callBack)(dispatch)
      .then((foundActiveKey) => {if (!foundActiveKey) {this.focusInheritedTab()}})
  }

  showMoreInheritedButton() {
    const {
      applicationState: {listDeveloperKeys: {listInheritedDeveloperKeysPending, inheritedNextPage}}
    } = this.props

    if (inheritedNextPage && !listInheritedDeveloperKeysPending) {
      return (
        <Button onClick={this.showMoreInheritedButtonHandler}>
          {I18n.t("Show All Keys")}
        </Button>)
    }
    return null
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
    return (
      <div>
        <View
          as="div"
          margin="0 0 small 0"
          padding="none"
        >
          <Heading level="h1">{I18n.t('Developer Keys')}</Heading>
        </View>
        <TabList variant="minimal" focus={this.state.focusTab}>
          <TabPanel title={I18n.t('Account')}>
            <View
              as="div"
              margin="0 0 small 0"
              padding="none"
              textAlign="end"
            >
              <Button
                variant="primary"
                onClick={this.showCreateDeveloperKey}
                buttonRef={this.setAddKeyButtonRef}
              >
                <ScreenReaderContent>{I18n.t('Create a')}</ScreenReaderContent>
                <IconPlusLine />
                { I18n.t('Developer Key') }
              </Button>
            </View>
            <DeveloperKeyModal
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
            <View
              as="div"
              margin="small"
              padding="large"
              textAlign="center"
            >
              {listDeveloperKeysPending ? <Spinner title={I18n.t('Loading')} /> : null}
              {this.showMoreButton()}
            </View>
          </TabPanel>
          {
            this.isSiteAdmin
              ? null
              : <TabPanel
                title={I18n.t('Inherited')}
                tabRef={this.setInheritedTabRef}
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
                <View
                  as="div"
                  margin="small"
                  padding="large"
                  textAlign="center"
                >
                  {listInheritedDeveloperKeysPending ? <Spinner title={I18n.t('Loading')} /> : null}
                  {this.showMoreInheritedButton()}
                </View>
              </TabPanel>
          }
        </TabList>
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
  }).isRequired,
}

export default DeveloperKeysApp
