define([
  'react',
  'react-dom',
  './NewUserTutorialToggleButton'
], (React, ReactDOM, NewUserTutorialToggleButton) => {
  const initializeNewUserTutorials = () => {
    if (window.ENV.NEW_USER_TUTORIALS.is_enabled) {
      const isCollapsed = true;
      ReactDOM.render(
        <NewUserTutorialToggleButton
          onClick={() => { console.log('yay') }}
          initiallyCollapsed={isCollapsed}
        />
        , document.querySelector('.TutorialToggleHolder')
      )
    }
  };

  return initializeNewUserTutorials;
});
