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
import DeveloperKeyStateControl from './DeveloperKeyStateControl'


class DeveloperKey extends React.Component {
  constructor (props) {
    super(props);
    this.activateLinkHandler = this.activateLinkHandler.bind(this);
    this.deactivateLinkHandler = this.deactivateLinkHandler.bind(this);
    this.editLinkHandler = this.editLinkHandler.bind(this);
    this.deleteLinkHandler = this.deleteLinkHandler.bind(this);
    this.focusDeleteLink = this.focusDeleteLink.bind(this);
    this.makeVisibleLinkHandler = this.makeVisibleLinkHandler.bind(this);
    this.makeInvisibleLinkHandler = this.makeInvisibleLinkHandler.bind(this);
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

  makeVisibleLinkHandler (event)
  {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.makeVisibleDeveloperKey(
        this.props.developerKey
      )
    )
  }

  makeInvisibleLinkHandler (event)
  {
    event.preventDefault()
    this.props.store.dispatch(
      this.props.actions.makeInvisibleDeveloperKey(
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
    this.props.store.dispatch(
      this.props.actions.setEditingDeveloperKey(
        this.props.developerKey
      )
    )
    this.props.store.dispatch(
      this.props.actions.developerKeysModalOpen()
    )
  }

  developerName (developerKey) {
    return developerKey.name || I18n.t('Unnamed Tool')
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

  focusDeleteLink() {
    this.deleteLink.focus();
  }

  focusName() {
    this.keyName.focus();
  }

  getLinkHelper(options) {
    const iconClassName = `icon-${options.iconType} standalone-icon`
    return (
      <a href="#"
        role={options.role}
        aria-checked={options.ariaChecked} aria-label={options.ariaLabel}
        className={options.className} title={options.title}
        ref={options.refLink}
        onClick={options.onClick}>
          <i className={iconClassName} />
      </a>)
  }

  getEditLink(developerName) {
    return this.getLinkHelper({
      ariaChecked: null,
      ariaLabel: I18n.t("Edit key %{developerName}", {developerName}),
      className: "edit_link",
      title: I18n.t("Edit this key"),
      onClick: this.editLinkHandler,
      iconType: "edit"
    })
  }

  refDeleteLink = (link) => { this.deleteLink = link; }
  refKeyName = (link) => { this.keyName = link; }

  getDeleteLink(developerName) {
    return this.getLinkHelper({
      ariaChecked: null,
      ariaLabel: I18n.t("Delete key %{developerName}", {developerName}),
      className: "delete_link",
      title: I18n.t("Delete this key"),
      onClick: this.deleteLinkHandler,
      iconType: "trash",
      refLink: this.refDeleteLink
    })
  }

  getMakeVisibleLink() {
    const label = I18n.t("Make key visible")
    return this.getLinkHelper({
      role: "checkbox",
      ariaChecked: false,
      ariaLabel: label,
      className: "deactivate_link",
      title: label,
      onClick: this.makeVisibleLinkHandler,
      iconType: "off",
    })
  }

  getMakeInvisibleLink() {
    const label = I18n.t("Make key invisible")
    return this.getLinkHelper({
      role: "checkbox",
      ariaChecked: true,
      ariaLabel: label,
      className: "deactivate_link",
      title: label,
      onClick: this.makeInvisibleLinkHandler,
      iconType: "eye",
    })
  }

  links (developerKey) {
    const developerNameCached = this.developerName(developerKey)
    const editLink = this.getEditLink(developerNameCached)
    const deleteLink = this.getDeleteLink(developerNameCached)
    const makeVisibleLink = this.getMakeVisibleLink()
    const makeInvisibleLink = this.getMakeInvisibleLink()

    return (
      <div>
        {editLink}
        {developerKey.visible ? makeInvisibleLink : makeVisibleLink}
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
        altText = I18n.t("Unnamed Tool Logo")
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

  render () {
    const { developerKey, inherited } = this.props;

    return (
      <tr className={classNames('key', { inactive: !this.isActive(developerKey) })}>
        <td className="name">
          {this.makeImage(developerKey)}
          <span ref={this.refKeyName}>
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
            {this.links(developerKey)}
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
    api_key: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired
  }).isRequired,
  ctx: PropTypes.shape({
    params: PropTypes.shape({
      contextId: PropTypes.string.isRequired
    })
  }).isRequired,
  inherited: PropTypes.bool
};

DeveloperKey.defaultProps = { inherited: false }

export default DeveloperKey
