define([
  'react',
  'react-dom',
  'axios',
  './NewUserTutorialToggleButton',
  './trays/TutorialTray',
  './utils/getProperTray',
  './utils/createTutorialStore',
  'compiled/str/splitAssetString',
], (React, ReactDOM, axios, NewUserTutorialToggleButton, TutorialTray, getProperTray, createTutorialStore, splitAssetString) => {
  const initializeNewUserTutorials = () => {
    if (window.ENV.NEW_USER_TUTORIALS &&
        window.ENV.NEW_USER_TUTORIALS.is_enabled &&
        (window.ENV.context_asset_string && (splitAssetString(window.ENV.context_asset_string)[0] === 'courses'))) {
      const API_URL = '/api/v1/users/self/new_user_tutorial_statuses';
      axios.get(API_URL)
           .then((response) => {
             let onPageToggleButton;
             const trayObj = getProperTray();
             const collapsedStatus = response.data.new_user_tutorial_statuses.collapsed[trayObj.pageName];
             const store = createTutorialStore({
               isCollapsed: collapsedStatus
             });

             store.addChangeListener(() => {
               axios.put(`${API_URL}/${trayObj.pageName}`, {
                 collapsed: store.getState().isCollapsed
               });
             });

             const getReturnFocus = () => onPageToggleButton;

             const renderTray = () => {
               const Tray = trayObj.component;
               ReactDOM.render(
                 <TutorialTray
                   store={store}
                   returnFocusToFunc={getReturnFocus}
                   label={trayObj.label}
                 >
                   <Tray />
                 </TutorialTray>
                 , document.querySelector('.NewUserTutorialTray__Container')
               );
             }
             ReactDOM.render(
               <NewUserTutorialToggleButton
                 ref={(c) => { onPageToggleButton = c; }}
                 store={store}
               />
               , document.querySelector('.TutorialToggleHolder'),
               () => renderTray()
             );
           });
    }
  };

  return initializeNewUserTutorials;
});
