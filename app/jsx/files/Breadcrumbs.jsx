define([
  'react',
  'i18n!react_files',
  'classnames',
  'compiled/react_files/components/Breadcrumbs',
  'compiled/react_files/modules/filesEnv',
  'jsx/files/BreadcrumbCollapsedContainer',
  'compiled/str/splitAssetString'
], function(React, I18n, classnames, Breadcrumbs, filesEnv, BreadcrumbCollapsedContainer, splitAssetString) {

  var MAX_CRUMB_WIDTH = 500
  var MIN_CRUMB_WIDTH = 80;

  Breadcrumbs.renderSingleCrumb = function (folder, isLastCrumb, isRootCrumb) {
    const [contextType, contextId] = splitAssetString(this.props.contextAssetString, false);
    const isContextRoot = !!(folder && (folder.get("context_type") || "").toLowerCase() === contextType && (folder.get("context_id") || -1).toString() === contextId);
    const name = (isRootCrumb  && isContextRoot) ? I18n.t('files', 'Files') : folder && (folder.get('custom_name') || folder.get('name'));

    return (
      <li key={name}>
        <a
          href={(isRootCrumb && isContextRoot) ? filesEnv.baseUrl : `${filesEnv.baseUrl}/folder/${(folder) ? folder.urlPath(): null}`}
          // only add title tooltips if there's a chance they could be ellipsized
          title={(this.state.maxCrumbWidth < 500) ? name : null}
        >
          <span
            className='ellipsis'
            style={{maxWidth: (isLastCrumb) ? null : this.state.maxCrumbWidth}}
          >
            {name}
          </span>
        </a>
      </li>
    );

  };

  Breadcrumbs.renderDynamicCrumbs = function () {
    if (this.props.showingSearchResults) {
      return [
        this.renderSingleCrumb(null, !'isLastCrumb', !!'isRootCrumb'),
        <li key='searchLink'>
          <a href="/search">
            <span className='ellipsis'>
              {this.props.query.search_term &&
                I18n.t('search_results_for', 'search results for "%{search_term}"', {search_term: this.props.query.search_term})
              }
            </span>
          </a>
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
