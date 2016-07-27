define([
  'i18n!external_tools',
  'react',
  'page',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/AddApp',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, React, page, Header, AddApp) {

  return React.createClass({
    displayName: 'AppDetails',

    propTypes: {
      store: React.PropTypes.object.isRequired,
      baseUrl: React.PropTypes.string.isRequired,
      shortName: React.PropTypes.string.isRequired
    },

    getInitialState() {
      return {
        app: null
      }
    },

    componentDidMount() {
      var app = this.props.store.findAppByShortName(this.props.shortName);
      if (app) {
        this.setState({ app: app });
      } else {
        page('/');
      }
    },

    handleToolInstalled() {
      var app = this.state.app;
      app.is_installed = true;
      this.setState({ app: app });
      this.props.store.flagAppAsInstalled(app.short_name);
      this.props.store.setState({filter: 'installed', filterText: ''});
      $.flashMessage(I18n.t('The app was added successfully'));
      page('/');
    },

    alreadyInstalled() {
      if (this.state.app.is_installed) {
        return <div className="gray-box-centered">{I18n.t('Installed')}</div>;
      }
    },

    render() {
      if (!this.state.app) {
        return <img src="/images/ajax-loader-linear.gif" />;
      }

      return (
        <div className="AppDetails">
          <Header>
            <a href={`${this.props.baseUrl}/configurations`} className="btn view_tools_link lm pull-right">{I18n.t('View App Configurations')}</a>
            <a href={this.props.baseUrl} className="btn view_tools_link lm pull-right">{I18n.t('View App Center')}</a>
          </Header>
          <div className="app_full">
            <table className="individual-app">
              <tbody>
                <tr>
                  <td className="individual-app-left" valign="top">
                    <div className="app">
                      <img className="img-polaroid" src={this.state.app.banner_image_url} />
                      {this.alreadyInstalled()}
                    </div>
                    <AddApp ref="addAppButton" app={this.state.app} handleToolInstalled={this.handleToolInstalled} />

                    <a href={this.props.baseUrl} className="app_cancel">&laquo; {I18n.t('Back to App Center')}</a>
                  </td>
                  <td className="individual-app-right" valign="top">
                    <h2 ref="appName">{this.state.app.name}</h2>
                    <p ref="appDescription" dangerouslySetInnerHTML={{__html: this.state.app.description}} />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      )
    }
  });

});
