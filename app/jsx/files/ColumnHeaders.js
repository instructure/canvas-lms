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

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!react_files'
import React from 'react'
import classnames from 'classnames'
import ColumnHeaders from 'compiled/react_files/components/ColumnHeaders'

    ColumnHeaders.renderColumns = function (sort, order) {
      return this.columns.map((column) => {
        if (column.property === 'usage_rights' && !this.props.usageRightsRequiredForContext) {
          return;
        }
        var isSortedCol = sort === column.property;
        var columnClassNameObj = {
          "current-filter": isSortedCol
        };
        columnClassNameObj[column.className] = true;
        var columnClassName = classnames(columnClassNameObj);
        var linkClassName = classnames({
          'visible-desktop': column.displayNameShort,
          'ef-usage-rights-col-offset': (column.property === 'usage_rights')
        });

        const encoded_path = this.props.pathname.split('/').map((part) => window.encodeURIComponent(part)).join('/');
        const href = `${encoded_path}?${$.param(this.queryParamsFor(this.props.query, column.property))}`;
        const linkProps = {
          className: 'ef-plain-link',
          href
        };
        var linkText;
        if (column.property === 'select') {
          linkText = <span className='screenreader-only'>{column.displayName}</span>;
        } else if (column.property == 'usage_rights') {
          linkText = (<i className='icon-files-copyright'>
                          <span className='screenreader-only'>{column.displayName}</span>
                        </i>
                     );
        } else {
          linkText = column.displayName;
        }

        return (
          <div
            key={column.property}
            className={columnClassName}
            role='columnheader'
            aria-sort={{asc: 'ascending', desc: 'descending'}[isSortedCol && order] || 'none'}
          >
            <a {...linkProps}>
              <span className={linkClassName}>
                {linkText}
              </span>
            {column.displayNameShort && (
              <span className='hidden-desktop'>{column.displayNameShort}</span>
            )}
            {isSortedCol && order === 'asc' && (
              <i className='icon-mini-arrow-up'>
                <span className='screenreader-only'>
                  {I18n.t('sorted_ascending', "Sorted Ascending")}
                </span>
              </i>
            )}
            {isSortedCol && order === 'desc' && (
              <i className='icon-mini-arrow-down'>
                <span className='screenreader-only'>
                  {I18n.t('sorted_desending', "Sorted Descending")}
                </span>
              </i>
            )}
          </a>
        </div>
        );
      })
    }

    ColumnHeaders.render = function () {
      const sort = this.props.query.sort || 'name';
      const order = this.props.query.order || 'asc';

      const selectAllCheckboxClass = classnames({
        'screenreader-only': this.state.hideToggleAll
      });

      const selectAllLabelClass = classnames({
        'screenreader-only': !this.state.hideToggleAll
      });

      return (
        <header className='ef-directory-header' role='row'>
          <div className={selectAllCheckboxClass} role='gridcell'>
            <label htmlFor='selectAllCheckbox' className={selectAllLabelClass}>
              {I18n.t('select_all', 'Select All')}
            </label>
            <input
              id='selectAllCheckbox'
              className={selectAllCheckboxClass}
              type='checkbox'
              onFocus={(event) => this.setState({hideToggleAll: false})}
              onBlur={(event) => this.setState({hideToggleAll: true})}
              checked={this.props.areAllItemsSelected()}
              onChange={(event) => this.props.toggleAllSelected(event.target.checked)}
            />
          </div>
        {this.renderColumns(sort, order)}
        <div
          className='ef-links-col'
          role='columnheader'
        >
          <span className='screenreader-only'>
            {I18n.t('Links')}
          </span>
        </div>
      </header>
    );
  }

export default React.createClass(ColumnHeaders)
