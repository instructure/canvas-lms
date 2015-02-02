/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'jsx/external_apps/lib/store'
], function (I18n, React, store) {

  return React.createClass({
    displayName: 'AppFilters',

    getInitialState() {
      return store.getState();
    },

    onChange() {
      this.setState(store.getState());
    },

    componentDidMount: function() {
      store.addChangeListener(this.onChange);
    },

    componentWillUnmount: function() {
      store.removeChangeListener(this.onChange);
    },

    handleFilterClick(filter, e) {
      e.preventDefault();
      store.setState({ filter: filter });
    },

    applyFilter() {
      var filterText = this.refs.filterText.getDOMNode().value;
      store.setState({ filterText: filterText });
    },

    render() {
      var activeFilter = this.state.filter || 'all';
      return (
        <div className="AppFilters">
          <div className="content-box">
            <div className="grid-row">
              <div className="col-xs-7">
                <ul className="nav nav-pills">
                  <li className={activeFilter === 'all' ? 'active' : ''}>
                    <a onClick={this.handleFilterClick.bind(this, 'all')} href="#" role="tab" aria-selected="false">{I18n.t('All')}</a>
                  </li>
                  <li className={activeFilter === 'not_installed' ? 'active' : ''}>
                    <a onClick={this.handleFilterClick.bind(this, 'not_installed')} href="#" role="tab" aria-selected="false">{I18n.t('Not Installed')}</a>
                  </li>
                  <li className={activeFilter === 'installed' ? 'active' : ''}>
                    <a onClick={this.handleFilterClick.bind(this, 'installed')} href="#" role="tab" aria-selected="false">{I18n.t('Installed')}</a>
                  </li>
                </ul>
              </div>
              <div className="col-xs-5">
                <label htmlFor="filterText" className="screenreader-only">{I18n.t('Filter by name')}</label>
                <input type="text"
                  id="filterText"
                  ref="filterText"
                  defaultValue={this.state.filterText}
                  className="input-block-level search-query"
                  placeholder={I18n.t('Filter by name')}
                  onKeyUp={this.applyFilter} />
              </div>
            </div>
          </div>
        </div>
      )
    }
  });
});