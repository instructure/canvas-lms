/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import classnames from 'classnames'
import filesEnv from 'compiled/react_files/modules/filesEnv'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'

  const BreadcrumbCollapsedContainer = React.createClass({

    displayName: 'BreadcrumbCollapsedContainer',

    propTypes: {
      foldersToContain: PropTypes.arrayOf(customPropTypes.folder).isRequired
    },

    getInitialState () {
      return {
        open: false
      };
    },

    open () {
      window.clearTimeout(this.timeout);
      this.setState({
        open: true
      });
    },

    close () {
      this.timeout = window.setTimeout(() => {
        this.setState({
          open: false
        });
      }, 100);
    },

    render () {
      var divClasses = classnames({
        'open': this.state.open,
        'closed': !this.state.open,
        'popover': true,
        'bottom': true,
        'ef-breadcrumb-popover': true
      });

      return (
        <li href = '#'
          onMouseEnter={this.open}
          onMouseLeave={this.close}
          onFocus={this.open}
          onBlur={this.close}
          style={{position: 'relative'}}
        >
          <a href='#'>…</a>
          <div className={divClasses}>
            <div className='arrow' />
            <div className='popover-content'>
              <ul>
                {this.props.foldersToContain.map((folder) => {
                  return (
                    <li key={folder.cid}>
                      <a
                        href={(folder.urlPath()) ? `${filesEnv.baseUrl}/folder/${folder.urlPath()}`: filesEnv.baseUrl}
                        activeClassName='active'
                        className='ellipsis'
                      >
                        <i className='ef-big-icon icon-folder' />
                        <span>{folder.get('name')}</span>
                      </a>
                    </li>
                  );
                })}
              </ul>
            </div>
          </div>
        </li>
      );
    }
  });

export default BreadcrumbCollapsedContainer
