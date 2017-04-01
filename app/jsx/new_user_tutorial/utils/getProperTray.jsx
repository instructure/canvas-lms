define([
  'i18n!new_user_tutorials',
  '../trays/HomeTray',
  '../trays/ModulesTray',
  '../trays/PagesTray',
  '../trays/AssignmentsTray',
  '../trays/QuizzesTray',
  '../trays/SettingsTray',
  '../trays/FilesTray',
  '../trays/PeopleTray',
  '../trays/AnnouncementsTray',
  '../trays/GradesTray'
], (I18n, HomeTray, ModulesTray, PagesTray, AssignmentsTray, QuizzesTray, SettingsTray,
  FilesTray, PeopleTray, AnnouncementsTray, GradesTray) => {
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
    } else if (path.includes('quizzes')) {
      return generateObject(QuizzesTray, I18n.t('Quizzes Tutorial Tray'), 'quizzes');
    } else if (path.includes('settings')) {
      return generateObject(SettingsTray, I18n.t('Settings Tutorial Tray'), 'settings');
    } else if (path.includes('files')) {
      return generateObject(FilesTray, I18n.t('Files Tutorial Tray'), 'files');
    } else if (path.includes('users')) {
      return generateObject(PeopleTray, I18n.t('People Tutorial Tray'), 'people');
    } else if (path.includes('announcements')) {
      return generateObject(AnnouncementsTray, I18n.t('Announcements Tutorial Tray'), 'announcements');
    } else if (path.includes('gradebook')) {
      return generateObject(GradesTray, I18n.t('Gradebook Tutorial Tray'), 'grades');
    }
    return generateObject(HomeTray, I18n.t('Home Tutorial Tray'), 'home');
  }

  return getProperTray;
});
