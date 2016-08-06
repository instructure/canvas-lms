define([
  "i18n!user_actions"
], function(I18n) {

  const TabActions = {
    selectTab(tabIndex) {
      return {
        type: 'SELECT_TAB',
        payload: {
          tabIndex: tabIndex
        }
      };
    }
  };

  return TabActions;
});
