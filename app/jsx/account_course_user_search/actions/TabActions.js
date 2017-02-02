import I18n from 'i18n!user_actions'

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

export default TabActions
