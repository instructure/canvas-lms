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

import Button from '@instructure/ui-core/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import TabList, { TabPanel } from '@instructure/ui-core/lib/components/TabList'

import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKeysTable from './DeveloperKeysTable'
import DeveloperKey from './DeveloperKey'
import DeveloperKeyModal from './DeveloperKeyModal'

class DeveloperKeysApp extends React.Component {
  setMainTableRef = (node) => {
    this.mainTableRef = node
  }

  setInheritedTableRef = (node) => {
    this.inheritedTableRef = node
  }

  showCreateDeveloperKey = () => {
    this.props.store.dispatch(this.props.actions.developerKeysModalOpen())
  }

  showMoreButtonHandler = (_event) => {
    const {
      applicationState: { listDeveloperKeys: { nextPage } },
      store: { dispatch },
      actions: { getRemainingDeveloperKeys }
    } = this.props
    this.mainTableRef.focusLastDeveloperKey()
    dispatch(getRemainingDeveloperKeys(nextPage, []))
  }

  showMoreButton () {
    const {
      applicationState: { listDeveloperKeys: { listDeveloperKeysPending, nextPage } }
    } = this.props

    if (nextPage && !listDeveloperKeysPending) {
      return (
        <Button type="button" onClick={this.showMoreButtonHandler}>
          {I18n.t("Show All Keys")}
        </Button>)
    }
    return null
  }

  showMoreInheritedButtonHandler = (_event) => {
    const {
      applicationState: { listDeveloperKeys: { inheritedNextPage } },
      store: { dispatch },
      actions: { getRemainingInheritedDeveloperKeys }
    } = this.props

    this.inheritedTableRef.focusLastDeveloperKey()
    dispatch(getRemainingInheritedDeveloperKeys(inheritedNextPage, []))
  }

  showMoreInheritedButton () {
    const {
      applicationState: { listDeveloperKeys: { listInheritedDeveloperKeysPending, inheritedNextPage } }
    } = this.props

    if (inheritedNextPage && !listInheritedDeveloperKeysPending) {
      return (
        <Button type="button" onClick={this.showMoreInheritedButtonHandler}>
          {I18n.t("Show All Keys")}
        </Button>)
    }
    return null
  }

  render () {
    const {
      applicationState: {
        listDeveloperKeys: { list, inheritedList, listDeveloperKeysPending, listInheritedDeveloperKeysPending },
        createOrEditDeveloperKey
      },
      store,
      actions,
      ctx
    } = this.props;
    return (
      <div>
        <div className="ic-Action-header">
          <div className="ic-Action-header__Primary">
            <h2 className="ic-Action-header__Heading">{I18n.t('Developer Keys')}</h2>
          </div>
          <div className="ic-Action-header__Secondary">
            <Button
              variant="primary"
              onClick={this.showCreateDeveloperKey}
            >
              <ScreenReaderContent>{I18n.t('Create a')}</ScreenReaderContent>
              <i className="icon-plus" />
              { I18n.t('Developer Key') }
            </Button>
          </div>
        </div>
        <TabList variant="minimal">
          <TabPanel title={I18n.t('Account')}>
            <DeveloperKeyModal
              store={store}
              actions={actions}
              createOrEditDeveloperKeyState={createOrEditDeveloperKey}
              ctx={ctx}
            />
            <DeveloperKeysTable
              ref={this.setMainTableRef}
              store={store}
              actions={actions}
              developerKeysList={list}
              ctx={ctx}
            />
            <div className="loadingSection">
              {listDeveloperKeysPending ? <Spinner title={I18n.t('Loading')} /> : null}
              {this.showMoreButton()}
            </div>
          </TabPanel>
          <TabPanel  title={I18n.t('Inherited')}>
            <DeveloperKeysTable
              ref={this.setInheritedTableRef}
              store={store}
              actions={actions}
              developerKeysList={inheritedList}
              ctx={ctx}
              inherited
            />
            <div className="loadingSection">
              {listInheritedDeveloperKeysPending ? <Spinner title={I18n.t('Loading')} /> : null}
              {this.showMoreInheritedButton()}
            </div>
          </TabPanel>
        </TabList>
      </div>
    );
  }
};

DeveloperKeysApp.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    developerKeysModalOpen: PropTypes.func.isRequired,
    getRemainingDeveloperKeys: PropTypes.func.isRequired,
    getRemainingInheritedDeveloperKeys: PropTypes.func.isRequired,
    setEditingDeveloperKey: PropTypes.func.isRequired
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
    }).isRequired
  }).isRequired,
  ctx: DeveloperKeyModal.propTypes.ctx
};

export default DeveloperKeysApp
