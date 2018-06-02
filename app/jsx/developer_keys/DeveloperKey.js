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

import classNames from 'classnames'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'
import 'jqueryui/dialog'
import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import Image from '@instructure/ui-core/lib/components/Image'
import Link from '@instructure/ui-core/lib/components/Link'

import DeveloperKeyActionButtons from './DeveloperKeyActionButtons'
import DeveloperKeyStateControl from './DeveloperKeyStateControl'


class DeveloperKey extends React.Component {
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

  developerName () {
    return this.props.developerKey.name || I18n.t('Unnamed Tool')
  }

  userName (developerKey) {
    if (developerKey.user_name) {
      return developerKey.user_name
    } else if(developerKey.email) {
      return I18n.t('Name Missing')
    }
    return I18n.t('No User')
  }

  isActive (developerKey) {
    return developerKey.workflow_state !== "inactive"
  }

  focusDeleteLink = () => {
    this.actionButtons.focusDeleteLink();
  }

  focusName() {
    this.keyName.focus();
  }

  makeImage (developerKey) {
    if (developerKey.icon_url) {
      return <span className="icon">
        <Image
          src={developerKey.icon_url}
          alt={I18n.t("%{developerName} Logo", {developerName: this.developerName()})}
        />
      </span>
    }
    return <span className="emptyIconImage" />
  }

  makeUserLink (developerKey) {
    const name = this.userName(developerKey)
    if (!developerKey.user_id) { return name }
    return (<Link href={`/users/${developerKey.user_id}`}>{name}</Link> );
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

  refActionButtons = (link) => { this.actionButtons = link; }
  refKeyName = (link) => { this.keyName = link; }

  render () {
    const { developerKey, inherited } = this.props;

    return (
      <tr className={classNames('key', { inactive: !this.isActive(developerKey) })}>
        <td className="name">
          {this.makeImage(developerKey)}
          <span ref={this.refKeyName} tabIndex="0">
            {this.developerName(developerKey)}
          </span>
        </td>

        {!inherited &&
          <td>
            <div>
              {this.makeUserLink(developerKey)}
            </div>
            <div>
              {developerKey.email}
            </div>
          </td>
        }

        <td>
          <div className="details">
            <div>
              {developerKey.id}
            </div>
            {!inherited &&
              <div>
                {I18n.t("Key:")} <span className='api_key'>{developerKey.api_key}</span>
              </div>
            }
            {!inherited &&
              <div>
                {this.redirectURI(developerKey)}
              </div>
            }
          </div>
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
            developerKey={developerKey}
            store={this.props.store}
            actions={this.props.actions}
            ctx={this.props.ctx}
          />
        </td>
        {!inherited &&
          <td className="icon_react">
            <DeveloperKeyActionButtons
              ref={this.refActionButtons}
              dispatch={this.props.store.dispatch}
              {...this.props.actions}
              developerKey={this.props.developerKey}
              visible={this.props.developerKey.visible}
              developerName={this.developerName()}
              onDelete={this.handleDelete}
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
    setEditingDeveloperKey: PropTypes.func.isRequired,
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
