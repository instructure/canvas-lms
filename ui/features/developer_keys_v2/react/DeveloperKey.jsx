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
import '@canvas/datetime/jquery'
import 'jqueryui/dialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {bool, func, number, shape, string} from 'prop-types'

import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconLtiLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {Popover} from '@instructure/ui-popover'
import {Link} from '@instructure/ui-link'
import {Img} from '@instructure/ui-img'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import DeveloperKeyActionButtons from './ActionButtons'
import DeveloperKeyStateControl from './InheritanceStateControl'

const I18n = useI18nScope('react_developer_keys')

class DeveloperKey extends React.Component {
  static displayName = 'Row'

  state = {showKey: false}

  get isSiteAdmin() {
    return this.props.ctx.params.contextId === 'site_admin'
  }

  activateLinkHandler = event => {
    event.preventDefault()
    this.props.store.dispatch(this.props.actions.activateDeveloperKey(this.props.developerKey))
  }

  deactivateLinkHandler = event => {
    event.preventDefault()
    this.props.store.dispatch(this.props.actions.deactivateDeveloperKey(this.props.developerKey))
  }

  getToolName() {
    return this.props.developerKey.name || I18n.t('Unnamed Tool')
  }

  ownerEmail(developerKey) {
    if (developerKey.email) {
      return developerKey.email
    }
    return I18n.t('No Email')
  }

  isActive(developerKey) {
    return developerKey.workflow_state !== 'inactive'
  }

  focusDeleteLink = () => {
    this.actionButtons.focusDeleteLink()
  }

  focusToggleGroup = () => {
    this.toggleGroup.focusToggleGroup()
  }

  isDisabled = () => this.toggleGroup.isDisabled()

  makeImage(developerKey) {
    if (developerKey.icon_url) {
      return (
        <Flex.Item as="div" width="4rem" height="4rem" textAlign="center" margin="0 small 0 0">
          <Img
            src={developerKey.icon_url}
            constrain="contain"
            alt={I18n.t('%{toolName} Logo', {toolName: this.getToolName()})}
          />
        </Flex.Item>
      )
    }
    return <Flex.Item as="div" height="4rem" width="4rem" margin="0 small 0 0" />
  }

  makeUserLink(developerKey) {
    const email = this.ownerEmail(developerKey)
    if (!developerKey.user_id) {
      return email
    }
    return <Link href={`/users/${developerKey.user_id}`}>{email}</Link>
  }

  redirectURI(developerKey) {
    if (!developerKey.redirect_uri) {
      return null
    }
    const uri = I18n.t('URI: %{redirect_uri}', {redirect_uri: developerKey.redirect_uri})
    return <div>{uri}</div>
  }

  lastUsed(developerKey) {
    const lastUsed = I18n.t('Last Used:')
    const lastUsedDate = developerKey.last_used_at ? developerKey.last_used_at : I18n.t('Never')
    return `${lastUsed} ${lastUsedDate}`
  }

  handleDelete = () => this.props.onDelete(this.props.developerKey.id)

  handleShowKey = () => {
    this.setState(state => ({showKey: !state.showKey}))
  }

  refActionButtons = link => {
    this.actionButtons = link
  }

  refToggleGroup = link => {
    this.toggleGroup = link
  }

  render() {
    const {developerKey, inherited} = this.props

    return (
      <Table.Row>
        <Table.Cell>
          <Flex>
            {this.makeImage(developerKey)}
            <Flex.Item shouldShrink={true}>{this.getToolName(developerKey)}</Flex.Item>
          </Flex>
        </Table.Cell>

        {!inherited && (
          <Table.Cell style={{wordBreak: 'break-all'}}>
            {this.makeUserLink(developerKey)}
          </Table.Cell>
        )}

        <Table.Cell>
          <View maxWidth="200px" as="div">
            <div>{developerKey.id}</div>
            {!inherited && (
              <div>
                <Popover
                  placement="top"
                  shouldAlignArrow={true}
                  on="click"
                  isShowingContent={this.state.showKey}
                  shouldContainFocus={true}
                  shouldReturnFocus={true}
                  shouldCloseOnDocumentClick={true}
                  onHideContent={this.handleShowKey}
                  screenReaderLabel={I18n.t('Key')}
                  renderTrigger={
                    <Button data-testid="show-key" onClick={this.handleShowKey} size="small">
                      {this.state.showKey ? I18n.t('Hide Key') : I18n.t('Show Key')}
                      <ScreenReaderContent>{this.getToolName()}</ScreenReaderContent>
                    </Button>
                  }
                >
                  <CloseButton
                    placement="end"
                    offset="x-small"
                    onClick={this.handleShowKey}
                    screenReaderLabel={I18n.t('Close')}
                  />
                  <View padding="large small small small" display="block">
                    {developerKey.api_key}
                  </View>
                </Popover>
              </div>
            )}
            {!inherited && (
              <div style={{wordBreak: 'break-all'}}>{this.redirectURI(developerKey)}</div>
            )}
          </View>
        </Table.Cell>

        {!inherited && (
          <Table.Cell>
            <div>
              {I18n.t('Access Token Count: %{access_token_count}', {
                access_token_count: developerKey.access_token_count,
              })}
            </div>
            <div>
              {I18n.t('Created: %{created_at}', {
                created_at: $.datetimeString(developerKey.created_at),
              })}
            </div>
            <div>{this.lastUsed(developerKey)}</div>
          </Table.Cell>
        )}
        <Table.Cell>
          {developerKey.is_lti_key ? (
            <Tooltip
              renderTip={I18n.t('Developer key is an external tool.')}
              on={['click', 'hover', 'focus']}
            >
              <IconButton
                renderIcon={IconLtiLine}
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Toggle ToolTip')}
              />
            </Tooltip>
          ) : null}
        </Table.Cell>
        <Table.Cell>
          <DeveloperKeyStateControl
            ref={this.refToggleGroup}
            developerKey={developerKey}
            store={this.props.store}
            actions={this.props.actions}
            ctx={this.props.ctx}
          />
        </Table.Cell>
        {!inherited && (
          <Table.Cell>
            <DeveloperKeyActionButtons
              ref={this.refActionButtons}
              contextId={this.props.ctx.params.contextId}
              dispatch={this.props.store.dispatch}
              {...this.props.actions}
              developerKey={this.props.developerKey}
              visible={this.props.developerKey.visible}
              developerName={this.getToolName()}
              onDelete={this.handleDelete}
              showVisibilityToggle={this.isSiteAdmin}
            />
          </Table.Cell>
        )}
      </Table.Row>
    )
  }
}

DeveloperKey.propTypes = {
  store: shape({
    dispatch: func.isRequired,
  }).isRequired,
  actions: shape({
    makeVisibleDeveloperKey: func.isRequired,
    makeInvisibleDeveloperKey: func.isRequired,
    activateDeveloperKey: func.isRequired,
    deactivateDeveloperKey: func.isRequired,
    deleteDeveloperKey: func.isRequired,
    editDeveloperKey: func.isRequired,
    developerKeysModalOpen: func.isRequired,
  }).isRequired,
  developerKey: shape({
    id: string.isRequired,
    access_token_count: number,
    api_key: string,
    created_at: string.isRequired,
    visible: bool,
    name: string,
    user_id: string,
    workflow_state: string,
    is_lti_key: bool,
  }).isRequired,
  ctx: shape({
    params: shape({
      contextId: string.isRequired,
    }),
  }).isRequired,
  inherited: bool,
  onDelete: func.isRequired,
}

DeveloperKey.defaultProps = {inherited: false}

export default DeveloperKey
