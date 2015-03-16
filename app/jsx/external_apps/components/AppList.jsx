/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'react-router',
  'jsx/external_apps/lib/AppCenterStore',
  'jsx/external_apps/components/AppTile',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/AppFilters'
], function(I18n, React, {Link, Navigation}, store, AppTile, Header, AppFilters) {

  return React.createClass({
    displayName: 'AppList',

    mixins: [ Navigation ],

    statics: {
      willTransitionTo: function(transition, params, query) {
        if (!ENV.APP_CENTER.enabled) {
          transition.redirect('configurations');
        }
      }
    },

    getInitialState() {
      return store.getState();
    },

    onChange() {
      this.setState(store.getState());
    },

    componentDidMount: function() {
      store.addChangeListener(this.onChange);
      store.fetch();
    },

    componentWillUnmount: function() {
      store.removeChangeListener(this.onChange);
    },

    apps() {
      if (store.getState().isLoading) {
        return <div ref="loadingIndicator" className="loadingIndicator"></div>;
      } else {
        return store.filteredApps().map(function (app, index) {
          return <AppTile key={index} app={app} />;
        });
      }
    },

    render() {
      return (
        <div className="AppList">
          <Header>
            <Link to="configurations" className="btn view_tools_link lm pull-right">{I18n.t('View App Configurations')}</Link>
          </Header>
          <AppFilters />
          <div className="app_center">
            <div className="app_list">
              <div className="collectionViewItems clearfix">
                {this.apps()}
              </div>
            </div>
          </div>
        </div>
      );
    }
  });

});