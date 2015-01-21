/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'old_unsupported_dont_use_react',
  'old_unsupported_dont_use_react-router',
  'jsx/external_apps/lib/AppCenterStore',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/AddApp',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, React, {Navigation, Link}, store, Header, AddApp) {

  return React.createClass({
    displayName: 'AppDetails',

    mixins: [Navigation],

    propTypes: {
      params: React.PropTypes.object.isRequired
    },

    getInitialState() {
      return {
        app: null
      }
    },

    componentDidMount() {
      var app = store.findAppByShortName(this.props.params.shortName);
      if (app) {
        this.setState({ app: app });
      } else {
        this.transitionTo('appList');
      }
    },

    handleToolInstalled() {
      var app = this.state.app;
      app.is_installed = true;
      this.setState({ app: app });
      store.flagAppAsInstalled(app.short_name);
      store.setState({filter: 'installed', filterText: ''});
      $.flashMessage(I18n.t('The app was added successfully'));
      this.transitionTo('appList');
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
            <Link to="configurations" className="btn view_tools_link lm pull-right">{I18n.t('View App Configurations')}</Link>
            <Link to="appList" className="btn view_tools_link lm pull-right">{I18n.t('View App Center')}</Link>
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

                    <Link to="appList" className="app_cancel">&laquo; {I18n.t('Back to App Center')}</Link>
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
