define([
  'i18n!new_user_tutorials',
  '../trays/HomeTray',
  '../trays/ModulesTray',
  '../trays/PagesTray',
  '../trays/AssignmentsTray'
], (I18n, HomeTray, ModulesTray, PagesTray, AssignmentsTray) => {
  const generateObject = (component, label, pageName) => ({
    component,
    label,
    pageName
  });

  const getProperTray = (path = window.location.pathname) => {
    if (path.includes('modules')) {
      return generateObject(ModulesTray, I18n.t('Modules Tutorial Tray'), 'modules');
    } else if (path.includes('pages')) {
      return generateObject(PagesTray, I18n.t('Pages Tutorial Tray'), 'pages');
    } else if (path.includes('assignments')) {
      return generateObject(AssignmentsTray, I18n.t('Assignments Tutorial Tray'), 'assignments');
    }
    return generateObject(HomeTray, I18n.t('Home Tutorial Tray'), 'home');
  }

  return getProperTray;
});
