import I18n from 'i18n!external_tools'
import React from 'react'
import store from 'jsx/external_apps/lib/AppCenterStore'
import extStore from 'jsx/external_apps/lib/ExternalAppsStore'
import AppTile from 'jsx/external_apps/components/AppTile'
import Header from 'jsx/external_apps/components/Header'
import AppFilters from 'jsx/external_apps/components/AppFilters'
import ManageAppListButton from 'jsx/external_apps/components/ManageAppListButton'
import splitAssetString from 'compiled/str/splitAssetString'

export default React.createClass({
    displayName: 'AppList',

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

    refreshAppList: function() {
      store.reset();
      store.fetch();
    },

    manageAppListButton() {
      var context_type = splitAssetString(ENV.context_asset_string, false)[0]
      if(context_type === 'account') {
        return <ManageAppListButton onUpdateAccessToken={this.refreshAppList} extAppStore={extStore}/>;
      } else {
        return null;
      }
    },

    apps() {
      if (store.getState().isLoading) {
        return <div ref="loadingIndicator" className="loadingIndicator"></div>;
      } else {
        return store.filteredApps().map((app, index) => {
          return <AppTile key={index} app={app} pathname={this.props.pathname} />;
        });
      }
    },

    render() {
      return (
        <div className="AppList">
          <Header>
            {this.manageAppListButton()}
            <a href={`${this.props.pathname}/configurations`} className="btn view_tools_link lm pull-right">{I18n.t('View App Configurations')}</a>
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
