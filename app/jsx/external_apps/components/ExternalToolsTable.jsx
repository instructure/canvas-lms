/** @jsx React.DOM */

define([
  'underscore',
  'i18n!external_tools',
  'react',
  'jsx/external_apps/lib/store',
  'jsx/external_apps/components/ExternalToolsTableRow'
], function(_, I18n, React, store, ExternalToolsTableRow) {
  return React.createClass({
    displayName: 'ExternalToolsTable',

    getInitialState() {
      return store.getState();
    },

    onChange() {
      this.setState(store.getState());
    },

    componentDidMount: function() {
      store.addChangeListener(this.onChange);
      store.fetchAll();
    },

    componentWillUnmount: function() {
      store.removeChangeListener(this.onChange);
    },

    trs() {
      return store.getState().externalTools.map(function (tool) {
        return <ExternalToolsTableRow key={tool.id} tool={tool} />
      }.bind(this));
    },

    render() {
      if (store.getState().isLoadingExternalTools) {
        return (
          <div className="ExternalToolsTable">
            <div className="loadingIndicator"></div>
          </div>
        );
      } else {
        return (
          <div className="ExternalToolsTable">
            <table className="table table-striped">
              <caption className="screenreader-only">{I18n.t('External Apps')}</caption>
              <thead>
                <tr>
                  <th scope="col" width="30%" style={{ 'padding-left': '30px' }}>{I18n.t('Name')}</th>
                  <th scope="col" width="50%">{I18n.t('Extensions')}</th>
                  <th scope="col" width="20%">&nbsp;</th>
                </tr>
              </thead>
              <tbody className="collectionViewItems">
                {this.trs()}
              </tbody>
            </table>
          </div>
        );
      }
    }
  });
});