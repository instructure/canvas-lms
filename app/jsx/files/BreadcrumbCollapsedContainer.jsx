/** @jsx React.DOM */

define([
  'i18n!react_files',
  'react',
  'classnames',
  'react-router',
  'compiled/react_files/components/BreadcrumbCollapsedContainer',
  ], function(I18n, React, classnames, ReactRouter, BreadcrumbCollapsedContainer) {

  var Link = ReactRouter.Link;

  BreadcrumbCollapsedContainer.render = function () {

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
                  <li>
                    <Link
                      to={(folder.urlPath()) ? 'folder': 'rootFolder'}
                      params={{splat: folder.urlPath()}}
                      activeClassName='active'
                      className='ellipsis'
                    >
                      <i className='ef-big-icon icon-folder' />
                      <span>{folder.get('name')}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      </li>
    );
  };

  return React.createClass(BreadcrumbCollapsedContainer);

});