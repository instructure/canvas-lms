/** @jsx React.DOM */

define([
  'underscore',
  'i18n!react_files',
  'react',
  'classnames',
  'react-router',
  'compiled/react_files/components/ColumnHeaders',
  ], function(_, I18n, React, classnames, ReactRouter, ColumnHeaders) {

    var Link = ReactRouter.Link;

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
        var linkProps = _.defaults({
              query: this.queryParamsFor(this.getQuery(), column.property),
              className: 'ef-plain-link'
            }, this.props);
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
            <Link {...linkProps}>
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
          </Link>
        </div>
        );
      })
    }

    ColumnHeaders.render = function () {
      var sort = this.getQuery().sort || 'name';
      var order = this.getQuery().order || 'asc';

      var selectAllCheckboxClass = classnames({
        'screenreader-only': this.state.hideToggleAll
      });

      var selectAllLabelClass = classnames({
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

  return React.createClass(ColumnHeaders);


});