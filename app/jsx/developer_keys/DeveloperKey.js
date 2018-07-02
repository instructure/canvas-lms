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
import 'jquery.instructure_date_and_time'
import 'jqueryui/dialog'
import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import Popover, { PopoverTrigger, PopoverContent } from '@instructure/ui-overlays/lib/components/Popover'
import Image from '@instructure/ui-elements/lib/components/Img'
import Link from '@instructure/ui-elements/lib/components/Link'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import View from '@instructure/ui-layout/lib/components/View'

import DeveloperKeyActionButtons from './ActionButtons'
import DeveloperKeyStateControl from './InheritanceStateControl'


class DeveloperKey extends React.Component {
  state = { showKey: false }

  get isSiteAdmin() {
    return this.props.ctx.params.contextId === "site_admin"
  }

  activateLinkHandler = (event) => {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.activateDeveloperKey(
        this.props.developerKey
      )
    )
  }

  deactivateLinkHandler = (event) => {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.deactivateDeveloperKey(
        this.props.developerKey
      )
    )
  }

  getToolName () {
    return this.props.developerKey.name || I18n.t('Unnamed Tool')
  }

  ownerEmail (developerKey) {
    if(developerKey.email) {
      return developerKey.email
    }
    return I18n.t('No Email')
  }

  isActive (developerKey) {
    return developerKey.workflow_state !== "inactive"
  }

  focusDeleteLink = () => {
    this.actionButtons.focusDeleteLink();
  }

  focusToggleGroup = () => {
    this.toggleGroup.focusToggleGroup();
  }

  isDisabled = () => ( this.toggleGroup.isDisabled() )

  makeImage (developerKey) {
    if (developerKey.icon_url) {
      return <FlexItem padding="0 xx-small 0 0">
        <Image
          src={developerKey.icon_url}
          cover
          width="4rem"
          height="4rem"
          margin="xxx-small xx-small xxx-small"
          alt={I18n.t("%{toolName} Logo", {toolName: this.getToolName()})}
        />
      </FlexItem>
    }
    return <View
      as="div"
      height="4rem"
      width="4rem"
    />
  }

  makeUserLink (developerKey) {
    const email = this.ownerEmail(developerKey)
    if (!developerKey.user_id) { return email }
    return (<Link href={`/users/${developerKey.user_id}`}>{email}</Link> );
  }

  redirectURI (developerKey) {
    if (!developerKey.redirect_uri) { return null }
    const uri = I18n.t("URI: %{redirect_uri}", {redirect_uri: developerKey.redirect_uri})
    return (<div>{uri}</div>)
  }

  lastUsed (developerKey) {
    const lastUsed = I18n.t("Last Used:")
    const lastUsedDate = developerKey.last_used_at ? developerKey.last_used_at : I18n.t("Never")
    return `${lastUsed} ${lastUsedDate}`
  }

  handleDelete = () => (
    this.props.onDelete(this.props.developerKey.id)
  )

  handleShowKey = () => {
    this.setState({showKey: !this.state.showKey})
  }

  refActionButtons = (link) => { this.actionButtons = link; }
  refToggleGroup = (link) => { this.toggleGroup = link }

  render () {
    const { developerKey, inherited } = this.props;

    return (
      <tr>
        <td>
          <Flex>
            {this.makeImage(developerKey)}
            <FlexItem shrink="true">
            {this.getToolName(developerKey)}
            </FlexItem>
          </Flex>
        </td>

        {!inherited &&
          <td style={{wordBreak: "break-all"}} width="200px">
              {this.makeUserLink(developerKey)}
          </td>
        }

        <td>
          <View
            maxWidth="200px"
            as="div"
          >
            <div>
              {developerKey.id}
            </div>
            {!inherited &&
              <div>
                <Popover
                  placement="top"
                  alignArrow
                  on="click"
                  show={this.state.showKey}
                  shouldContainFocus
                  shouldReturnFocus
                  shouldCloseOnDocumentClick
                  onDismiss={this.handleShowKey}
                  label={I18n.t("Key")}
                >
                  <PopoverTrigger>
                    <Button onClick={this.handleShowKey} size="small">
                      {
                        this.state.showKey ?
                          I18n.t('Hide Key') :
                          I18n.t('Show Key')
                      }
                      <ScreenReaderContent>
                        {this.getToolName()}
                      </ScreenReaderContent>
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent>
                    <CloseButton
                      placement="end"
                      offset="x-small"
                      variant="icon"
                      onClick={this.handleShowKey}
                    >
                      {I18n.t('Close')}
                    </CloseButton>
                    <View padding="large small small small" display="block">
                      { developerKey.api_key }
                    </View>
                  </PopoverContent>
                </Popover>
              </div>
            }
            {!inherited &&
              <div style={{wordBreak: "break-all"}}>
                {this.redirectURI(developerKey)}
              </div>
            }
          </View>
        </td>

        {!inherited &&
          <td>
            <div>
              {I18n.t("Access Token Count: %{access_token_count}", {access_token_count: developerKey.access_token_count})}
            </div>
            <div>
              {I18n.t("Created: %{created_at}", {created_at: $.datetimeString(developerKey.created_at)})}
            </div>
            <div>
              {this.lastUsed(developerKey)}
            </div>
          </td>
        }

        <td>
          <DeveloperKeyStateControl
            ref={this.refToggleGroup}
            developerKey={developerKey}
            store={this.props.store}
            actions={this.props.actions}
            ctx={this.props.ctx}
          />
        </td>
        {!inherited &&
          <td>
            <DeveloperKeyActionButtons
              ref={this.refActionButtons}
              dispatch={this.props.store.dispatch}
              {...this.props.actions}
              developerKey={this.props.developerKey}
              visible={this.props.developerKey.visible}
              toolName={this.getToolName()}
              onDelete={this.handleDelete}
              showVisibilityToggle={this.isSiteAdmin}
            />
          </td>
        }
      </tr>
    );
  };
}

DeveloperKey.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    makeVisibleDeveloperKey: PropTypes.func.isRequired,
    makeInvisibleDeveloperKey: PropTypes.func.isRequired,
    activateDeveloperKey: PropTypes.func.isRequired,
    deactivateDeveloperKey: PropTypes.func.isRequired,
    deleteDeveloperKey: PropTypes.func.isRequired,
    editDeveloperKey: PropTypes.func.isRequired,
    developerKeysModalOpen: PropTypes.func.isRequired
  }).isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    api_key: PropTypes.string,
    created_at: PropTypes.string.isRequired,
    visible: PropTypes.bool,
    name: PropTypes.string,
    user_id: PropTypes.string,
    workflow_state: PropTypes.string
  }).isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired,
  inherited: PropTypes.bool,
  onDelete: PropTypes.func.isRequired
};

DeveloperKey.defaultProps = { inherited: false }

export default DeveloperKey
