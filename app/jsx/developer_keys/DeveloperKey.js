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
import 'jqueryui/dialog'
import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import buildForm from './lib/buildForm'


class DeveloperKey extends React.Component {
  constructor (props) {
    super(props);
    this.activateLinkHandler = this.activateLinkHandler.bind(this);
    this.deactivateLinkHandler = this.deactivateLinkHandler.bind(this);
    this.editLinkHandler = this.editLinkHandler.bind(this);
    this.deleteLinkHandler = this.deleteLinkHandler.bind(this);
    this.focusDeleteLink = this.focusDeleteLink.bind(this);
  }

  activateLinkHandler (event)
  {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.activateDeveloperKey(
        this.props.developerKey
      )
    )
  }

  deactivateLinkHandler (event)
  {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.deactivateDeveloperKey(
        this.props.developerKey
      )
    )
  }

  deleteLinkHandler (event)
  {
    event.preventDefault()
    const confirmResult = confirm(I18n.t('Are you sure you want to delete this developer key?'))
    if (confirmResult) {
      this.props.store.dispatch(
        this.props.actions.deleteDeveloperKey(
          this.props.developerKey
        )
      )
    }
  }

  editLinkHandler (event)
  {
    event.preventDefault()
    const form = buildForm(this.props.developerKey)

    $('#edit_dialog')
      .empty()
      .append(form)
      .dialog('open')
  }

  developerName (developerKey) {
    return developerKey.name || 'Unnamed Tool'
  }

  userName (developerKey) {
    return developerKey.user_name || 'No User'
  }

  isActive (developerKey) {
    return developerKey.workflow_state !== "inactive"
  }

  inactive (developerKey) {
    return this.isActive(developerKey) ? null : (<div><i>{I18n.t("inactive")}</i></div>)
  }

  focusDeleteLink() {
    this.deleteLink.focus();
  }

  links (developerKey) {
    const developerNameCached = this.developerName(developerKey)

    const localizedActivateLabel = I18n.t("Activate key %{developerName}", {developerName: developerNameCached})

    const activateLink = (
      <a href="#" role="checkbox"
        aria-checked="false" aria-label={localizedActivateLabel}
        className="deactivate_link" title={I18n.t("Activate this key")}
        onClick={this.activateLinkHandler}>
          <i className="icon-unlock standalone-icon" />
      </a>)

    const localizedDeactivateLabel = I18n.t("Deactivate key %{developerName}", {developerName: developerNameCached})

    const deactivateLink = (
      <a href="#" role="checkbox"
        aria-checked="true" aria-label={localizedDeactivateLabel}
        className="deactivate_link" title={I18n.t("Deactivate this key")}
        onClick={this.deactivateLinkHandler}>
          <i className="icon-lock standalone-icon" />
      </a>)

    const localizedEditLabel = I18n.t("Edit key %{developerName}", {developerName: developerNameCached})

    const editLink = (
      <a href="#" className="edit_link"
        aria-label={localizedEditLabel}
        title={I18n.t("Edit this key")}
        onClick={this.editLinkHandler}>
          <i className="icon-edit standalone-icon" />
      </a>)

    const localizedDeleteLabel = I18n.t("Delete key %{developerName}", {developerName: developerNameCached})

    const deleteLink = (
      <a href="#" className="delete_link"
        aria-label={localizedDeleteLabel}
        title={I18n.t("Delete this key")}
        ref={(link) => { this.deleteLink = link; }}
        onClick={this.deleteLinkHandler}>
          <i className="icon-trash standalone-icon" />
      </a>)

    return (
      <div>
        {editLink}
        {this.isActive(developerKey) ? deactivateLink : activateLink}
        {deleteLink}
      </div>
    )
  }

  makeImage (developerKey) {
    let src = '#'
    let altText = ''
    if (developerKey.icon_url) {
      src = developerKey.icon_url
      if (developerKey.name) {
        altText = I18n.t("%{developerName} Logo", {developerName: developerKey.name})
      } else {
        altText = "Unnamed Tool Logo"
      }
    }

    return (<img className="icon" src={src} alt={altText} />)
  }

  makeUserLink (developerKey) {
    const name = this.userName(developerKey)
    if (!developerKey.user_id) { return name }
    return (<a href={`/users/${developerKey.user_id}`}>{name}</a> );
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

  notes (developerKey) {
    if (!developerKey.notes) { return null }
    return (<div>{developerKey.notes}</div>)
  }

  render () {
    const { developerKey } = this.props;

    return (
      <tr className={classNames('key', { inactive: !this.isActive(developerKey) })}>
        <td className="name">
          {this.makeImage(developerKey)}
          {this.developerName(developerKey)}
          {this.inactive(developerKey)}
        </td>

        <td>
          <div>
            {this.makeUserLink(developerKey)}
          </div>
          <div>
            {developerKey.email}
          </div>
        </td>

        <td>
          <div className="details">
            <div>
              {developerKey.id}
            </div>
            <div>
              {I18n.t("Key:")} <span className='api_key'>{developerKey.api_key}</span>
            </div>
            <div>
              {this.redirectURI(developerKey)}
            </div>
          </div>
        </td>

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

        <td className="notes">
          {this.notes(developerKey)}
        </td>

        <td className="icon_react">
          {this.links(developerKey)}
        </td>
      </tr>
    );
  };
}

DeveloperKey.propTypes = {
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    activateDeveloperKey: PropTypes.func.isRequired,
    deactivateDeveloperKey: PropTypes.func.isRequired,
    deleteDeveloperKey: PropTypes.func.isRequired,
  }).isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    api_key: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired
  }).isRequired
};

export default DeveloperKey
