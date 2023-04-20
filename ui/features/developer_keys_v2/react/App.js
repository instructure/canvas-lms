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
import DeveloperKeyModalTrigger from './NewKeyTrigger'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import DateHelper from '@canvas/datetime/dateHelper'

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

  buildDevKeyOIDCText(_features) {
    const today = new Date()
    const changeDate = new Date(1688212799000) // July 1, 2023 at 11:59:59 UTC
    const formattedDate = DateHelper.formatDateForDisplay(changeDate)
    const linkMarkup = `<a href="https://community.canvaslms.com/t5/The-Product-Blog/The-LTI-1-3-OIDC-Auth-Endpoint-is-Changing-You-Won-t-Believe-the/ba-p/551677">$1</a>`
    const secondParagraph = I18n.t(
      '*For LTI 1.3 Tool Developers:* Follow the directions in the "What exactly will you need to change?" section of the Community article.',
      {wrappers: [`<strong>$1</strong>`]}
    )
    const makeAlertMsg = (testid, first, third) => {
      return (
        <div data-testid={testid}>
          <View as="div" margin="small">
            <Text dangerouslySetInnerHTML={{__html: first}} />
          </View>
          <View as="div" margin="small">
            <Text dangerouslySetInnerHTML={{__html: secondParagraph}} />
          </View>
          <View as="div" margin="small">
            <Text dangerouslySetInnerHTML={{__html: third}} />
          </View>
        </div>
      )
    }

    if (changeDate > today) {
      const firstParagraph = I18n.t(
        'On %{date}, the LTI 1.3 OIDC Auth endpoint will be changing from https://canvas.instructure.com/api/lti/authorize_redirect to https://sso.canvaslms.com/api/lti/authorize_redirect. The reasoning and scope of this change is detailed in *this Canvas Community article*, and additional information is available in our API docs. This change is small, but requires configuration change on the tool side for every LTI 1.3 tool that is installed in Canvas.',
        {
          date: formattedDate,
          wrappers: [linkMarkup],
        }
      )
      const thirdParagraph = I18n.t(
        '*For Canvas Admins:* No actions or configuration changes are required on your part. You can ask developers of 1.3 tools that you have installed about the status of their needed changes.',
        {wrappers: [`<strong>$1</strong>`]}
      )

      return makeAlertMsg('preFlipText', firstParagraph, thirdParagraph)
    } else {
      const firstParagraph = I18n.t(
        'As of %{date}, the LTI 1.3 OIDC Auth endpoint has changed from https://canvas.instructure.com/api/lti/authorize_redirect to https://sso.canvaslms.com/api/lti/authorize_redirect. The reasoning and scope of this change is detailed in *this Canvas Community article*, and additional information is available in our API docs. This change is small and will not take very long, but requires configuration change on the tool side for every LTI 1.3 tool that is installed in Canvas.',
        {
          date: formattedDate,
          wrappers: [linkMarkup],
        }
      )
      const thirdParagraph = I18n.t(
        '*For Canvas Admins:* No actions or configuration changes are required on your part. You can confirm with developers of 1.3 tools that you have installed that they have made these changes.',
        {wrappers: [`<strong>$1</strong>`]}
      )

      return makeAlertMsg('postFlipText', firstParagraph, thirdParagraph)
    }
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
   */
  developerKeySaveSuccessfulHandler() {
    setTimeout(showFlashSuccess(I18n.t('Save successful.')), ALERT_WAIT_TIME)
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
        {ENV?.FEATURES?.dev_key_oidc_alert && (
          <div data-testid="OIDC_warning">
            <Alert variant="warning" margin="small">
              {this.buildDevKeyOIDCText(ENV.FEATURES)}
            </Alert>
          </div>
        )}
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
              handleSuccessfulSave={this.developerKeySaveSuccessfulHandler}
            />
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
