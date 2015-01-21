/** @jsx React.DOM */

define([
  'underscore',
  'i18n!external_tools',
  'old_unsupported_dont_use_react',
  'jsx/external_apps/lib/ExternalAppsStore',
  'jsx/external_apps/components/ExternalToolsTableRow',
  'jsx/external_apps/components/InfiniteScroll'
], function(_, I18n, React, store, ExternalToolsTableRow, InfiniteScroll) {

  return React.createClass({
    displayName: 'ExternalToolsTable',

    getInitialState() {
      return store.getState();
    },

    onChange() {
      this.setState(store.getState());
    },

    componentDidMount() {
      store.addChangeListener(this.onChange);
      store.fetch();
    },

    componentWillUnmount() {
      store.removeChangeListener(this.onChange);
    },

    loadMore(page) {
      if (store.getState().hasMore && !store.getState().isLoading) {
        store.fetch();
      }
    },

    loader() {
      return <div className="loadingIndicator"></div>;
    },

    trs() {
      if (store.getState().externalTools.length == 0) {
        return null;
      }
      return store.getState().externalTools.map(function (tool, idx) {
        return <ExternalToolsTableRow key={idx} tool={tool} />
      }.bind(this));
    },

    render() {
      return (
        <div className="ExternalToolsTable">
          <InfiniteScroll pageStart={0} loadMore={this.loadMore} hasMore={store.getState().hasMore} loader={this.loader()}>
            <table className="table table-striped">
              <caption className="screenreader-only">{I18n.t('External Apps')}</caption>
              <thead>
                <tr>
                  <th scope="col" width="70%">{I18n.t('Name')}</th>
                  <th scope="col" width="30%">&nbsp;</th>
                </tr>
              </thead>
              <tbody className="collectionViewItems">
                {this.trs()}
              </tbody>
            </table>
          </InfiniteScroll>
        </div>
      );
    }
  });
});