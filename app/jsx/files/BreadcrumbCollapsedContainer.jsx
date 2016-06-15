define([
  'i18n!react_files',
  'react',
  'classnames',
  'compiled/react_files/modules/filesEnv',
  'compiled/react_files/modules/customPropTypes',
  ], function(I18n, React, classnames, filesEnv, customPropTypes) {

  const BreadcrumbCollapsedContainer = React.createClass({

    displayName: 'BreadcrumbCollapsedContainer',

    propTypes: {
      foldersToContain: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
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

  return BreadcrumbCollapsedContainer;

});