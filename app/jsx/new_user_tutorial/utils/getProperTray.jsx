define([
  'i18n!new_user_tutorials',
  '../trays/HomeTray',
  '../trays/ModulesTray'
], (I18n, HomeTray, ModulesTray) => {
  const generateObject = (component, label) => ({
    component,
    label
  });

  const getProperTray = (path = window.location.pathname) => {
    if (path.includes('modules')) {
      return generateObject(ModulesTray, I18n.t('Modules Tutorial Tray'));
    }
    return generateObject(HomeTray, I18n.t('Home Tutorial Tray'));
  }

  return getProperTray;
});
