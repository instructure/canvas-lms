/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!help_dialog'
import Spinner from 'instructure-ui/lib/components/Spinner'

  const HelpLinks = React.createClass({
    propTypes: {
      links: PropTypes.array,
      hasLoaded: PropTypes.bool,
      onClick: PropTypes.func
    },
    getDefaultProps() {
      return {
        hasLoaded: false,
        links: [],
        onClick: function (url) {}
      };
    },
    handleLinkClick (e) {
      const url = e.target.getAttribute('href');
      if (url === '#create_ticket' || url === '#teacher_feedback') {
        e.preventDefault();
        this.props.onClick(url);
      }
    },
    render () {
      const links = this.props.links.map((link, index) => {
        return (
          <li className="ic-NavMenu-list-item" key={`link${index}`}>
            <a
              href={link.url}
              target="_blank"
              rel="noopener"
              onClick={this.handleLinkClick}
              className="ic-NavMenu-list-item__link"
            >
              {link.text}
            </a>
            {
              link.subtext ? (
                <div
                  className="ic-NavMenu-list-item__helper-text is-help-link">
                  {link.subtext}
                </div>
              ) : null
            }
          </li>
        );
      });

      // if the current user is an admin, show the settings link to
      // customize this menu
      if (window.ENV.current_user_roles.indexOf("root_admin") > -1) {
        links.push(
          <li key="admin" className="ic-NavMenu-list-item ic-NavMenu-list-item--feature-item">
            <a
              href="/accounts/self/settings"
              className="ic-NavMenu-list-item__link">
              {I18n.t('Customize this menu')}
            </a>
          </li>
        );
      }

      return (
        <ul className="ic-NavMenu__link-list">
          {this.props.hasLoaded ?
            links
            :
            <li className="ic-NavMenu-list-item ic-NavMenu-list-item--loading-message">
              <Spinner size="small" title={I18n.t('Loading')} />
            </li>
          }
        </ul>
      );
    }
  });

export default HelpLinks
