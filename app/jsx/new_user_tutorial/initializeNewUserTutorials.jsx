define([
  'react',
  'react-dom',
  './NewUserTutorialToggleButton',
  './trays/TutorialTray',
  './utils/getProperTray',
  './utils/createTutorialStore',
  'compiled/str/splitAssetString',
], (React, ReactDOM, NewUserTutorialToggleButton, TutorialTray, getProperTray, createTutorialStore, splitAssetString) => {
  const initializeNewUserTutorials = () => {
    if (window.ENV.NEW_USER_TUTORIALS.is_enabled &&
       (window.ENV.context_asset_string && (splitAssetString(window.ENV.context_asset_string)[0] === 'courses'))) {
      const store = createTutorialStore();
      let onPageToggleButton;

      const getReturnFocus = () => onPageToggleButton;

      const renderTray = () => {
        const trayObj = getProperTray();
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
        )
      }

      ReactDOM.render(
        <NewUserTutorialToggleButton
          ref={(c) => { onPageToggleButton = c; }}
          store={store}
        />
        , document.querySelector('.TutorialToggleHolder'),
        () => renderTray()
      )
    }
  };

  return initializeNewUserTutorials;
});
