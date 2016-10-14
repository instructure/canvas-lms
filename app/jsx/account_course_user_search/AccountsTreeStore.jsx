define([
  "react",
  "./createStore",
  "underscore"
], function(React, createStore, _) {

  var { string, shape, arrayOf } = React.PropTypes;

  var AccountsTreeStore = createStore({
    getUrl() {
      return `/api/v1/accounts/${this.context.accountId}/sub_accounts`;
    },

    loadTree() {
      var key = this.getKey();
      // fetch the account itself first, then get its subaccounts
      this._load(key, `/api/v1/accounts/${this.context.accountId}`, {}, {wrap: true}).then(() => {
        this.loadAll(null, true);
      });
    },

    normalizeParams() {
      return { recursive: true };
    },

    getTree() {
      var data = this.get();
      if (!data || !data.data) return [];
      var accounts = [];
      var idIndexMap = {};
      data.data.forEach(function(item, i) {
        var account = _.extend({}, item, {subAccounts: []});
        accounts.push(account);
        idIndexMap[account.id] = i;
      })
      accounts.forEach(function(account) {
        var parentIdx = idIndexMap[account.parent_account_id];
        if (typeof parentIdx === "undefined") return;
        accounts[parentIdx].subAccounts.push(account);
      });
      return [accounts[0]];
    }
  });

  AccountsTreeStore.PropType = shape({
    id: string.isRequired,
    parent_account_id: string,
    name: string.isRequired,
    subAccounts: arrayOf(
      function() { AccountsTreeStore.PropType.apply(this, arguments) }
    ).isRequired
  });

  return AccountsTreeStore;
});
