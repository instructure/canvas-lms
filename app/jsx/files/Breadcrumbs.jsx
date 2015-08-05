/** @jsx React.DOM */

define([
  'react',
  'i18n!react_files',
  'classnames',
  'react-router',
  'compiled/react_files/components/Breadcrumbs',
  'jsx/files/BreadcrumbCollapsedContainer'
], function(React, I18n, classnames, ReactRouter, Breadcrumbs, BreadcrumbCollapsedContainer) {

  var MAX_CRUMB_WIDTH = 500
  var MIN_CRUMB_WIDTH = (window.ENV.use_new_styles) ? 80 : 40;

  var Link = ReactRouter.Link;

  Breadcrumbs.renderSingleCrumb = function (folder, isLastCrumb, isRootCrumb) {
    var name = (isRootCrumb) ? I18n.t('files', 'Files') : folder.get('name');
    return (
      <li>
        <Link
          to={(isRootCrumb) ? 'rootFolder' : 'folder'}
          params={{splat: (isRootCrumb) ? null : folder.urlPath()}}
          // only add title tooltips if there's a chance they could be ellipsized
          title={(this.state.maxCrumbWidth < 500) ? name : null}
        >
          <span
            className='ellipsis'
            style={{maxWidth: (isLastCrumb) ? null : this.state.maxCrumbWidth}}
          >
            {name}
          </span>
        </Link>
      </li>
    );

  };

  Breadcrumbs.renderDynamicCrumbs = function () {
    if (this.props.showingSearchResults) {
      return [
        this.renderSingleCrumb(null, !'isLastCrumb', !!'isRootCrumb'),
        <li>
          <Link
            to='search'
            query={this.getQuery()}
            params={{splat: ''}}
          >
            <span className='ellipsis'>
              {this.getQuery().search_term &&
                I18n.t('search_results_for', 'search results for "%{search_term}"', {search_term: this.getQuery().search_term})
              }
            </span>
          </Link>
        </li>
      ];
    } else {
      if (!this.props.rootTillCurrentFolder || !this.props.rootTillCurrentFolder.length) {
        return [];
      }
      // Formerly, in CoffeeScript [...foldersInMiddle, lastFolder] = this.props.rootTillCurrentFolder
      var foldersInMiddle = this.props.rootTillCurrentFolder.slice(0, this.props.rootTillCurrentFolder.length - 1)
      var lastFolder = this.props.rootTillCurrentFolder[this.props.rootTillCurrentFolder.length - 1]

      if (this.state.maxCrumbWidth > MIN_CRUMB_WIDTH) {
        return this.props.rootTillCurrentFolder.map((folder, i) => {
          return this.renderSingleCrumb(folder, folder === lastFolder, i === 0)
        });
      } else {
        return [
          <BreadcrumbCollapsedContainer foldersToContain={foldersInMiddle} />,
          this.renderSingleCrumb(lastFolder, true)
        ]
      }
    }

  };

  Breadcrumbs.render = function () {
    return (
      <nav
        aria-label='breadcrumbs'
        role='navigation'
        id='breadcrumbs'
        ref='breadcrumbs'
      >
        <ul>
          <li className='home'>
            <a href='/'>
              <i className='icon-home standalone-icon' title={this.state.homeName}>
                <span className='screenreader-only'>{this.state.homeName}</span>
              </i>
            </a>
          </li>
          <li>
            <a href={this.state.contextUrl}>
              <span className='ellipsible'>
                {this.state.contextName}
              </span>
            </a>
          </li>
          {this.renderDynamicCrumbs()}
        </ul>
      </nav>
    );
  };

  return React.createClass(Breadcrumbs);
});