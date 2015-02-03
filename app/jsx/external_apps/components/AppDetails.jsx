/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'react-router',
  'jsx/external_apps/lib/store',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/AddApp',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, React, {Navigation, Link}, store, Header, AddApp) {

  return React.createClass({
    displayName: 'AppDetails',

    mixins: [Navigation],

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
      app.attributes.is_installed = true;
      this.setState({ app: app });
      store.flagAppAsInstalled(app.attributes.short_name);
      store.fetchExternalTools(true);
      store.setState({filter: 'installed', filterText: ''});
      $.flashMessage(I18n.t('The app was added successfully'));
      this.transitionTo('appList');
    },

    alreadyInstalled() {
      if (this.state.app.attributes.is_installed) {
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
                      <img className="img-polaroid" src={this.state.app.attributes.banner_image_url} />
                      {this.alreadyInstalled()}
                    </div>
                    <AddApp ref="addAppButton" app={this.state.app} handleToolInstalled={this.handleToolInstalled} />

                    <Link to="appList" className="app_cancel">&laquo; {I18n.t('Back to App Center')}</Link>
                  </td>
                  <td className="individual-app-right" valign="top">
                    <h2>{this.state.app.attributes.name}</h2>
                    <p dangerouslySetInnerHTML={{__html: this.state.app.attributes.description}} />
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
