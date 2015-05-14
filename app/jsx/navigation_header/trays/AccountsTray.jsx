/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  SVGWrapper = React.createFactory(SVGWrapper);

  var AccountsTray = React.createClass({
    propTypes: {
      accounts: React.PropTypes.array.isRequired
    },

    getDefaultProps() {
      return {
        accounts: []
      };
    },

    renderAccounts() {
      return this.props.accounts.map((account) => {
        return <li key={account.id}><a href={`/accounts/${account.id}`}>{account.name}</a></li>;
      });
    },

    render() {
      return (
        <div>
          <h1>{I18n.t('Accounts')}</h1>
          <ul>
            {this.renderAccounts()}
          </ul>
        </div>
      );
    }
  });

  return AccountsTray;

});
