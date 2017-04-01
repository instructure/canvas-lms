define([
  'jsx/new_user_tutorial/utils/getProperTray',
  'jsx/new_user_tutorial/trays/HomeTray',
  'jsx/new_user_tutorial/trays/ModulesTray',
  'jsx/new_user_tutorial/trays/PagesTray',
  'jsx/new_user_tutorial/trays/AssignmentsTray',
  'jsx/new_user_tutorial/trays/QuizzesTray',
  'jsx/new_user_tutorial/trays/SettingsTray',
  'jsx/new_user_tutorial/trays/FilesTray',
  'jsx/new_user_tutorial/trays/PeopleTray',
  'jsx/new_user_tutorial/trays/AnnouncementsTray',
  'jsx/new_user_tutorial/trays/GradesTray'
], (getProperTray, HomeTray, ModulesTray, PagesTray, AssignmentsTray, QuizzesTray,
    SettingsTray, FilesTray, PeopleTray, AnnouncementsTray, GradesTray) => {
  QUnit.module('getProperTray test');

  test('if no match is in the path argument returns the HomeTray', () => {
    const trayObj = getProperTray('/courses/3');
    equal(trayObj.component, HomeTray, 'component matches');
    equal(trayObj.label, 'Home Tutorial Tray', 'label matches');
  });

  test('if modules is in the path argument returns the ModulesTray', () => {
    const trayObj = getProperTray('/courses/3/modules/');
    equal(trayObj.component, ModulesTray, 'component matches');

    equal(trayObj.label, 'Modules Tutorial Tray', 'label matches');
  });

  test('if pages is in the path argument returns the PagesTray', () => {
    const trayObj = getProperTray('/courses/3/pages/');
    equal(trayObj.component, PagesTray, 'component matches');

    equal(trayObj.label, 'Pages Tutorial Tray', 'label matches');
  });

  test('if assignments is in the path argument returns the AssignmentsTray', () => {
    const trayObj = getProperTray('/courses/3/assignments/');
    equal(trayObj.component, AssignmentsTray, 'component matches');

    equal(trayObj.label, 'Assignments Tutorial Tray', 'label matches');
  });

  test('if quizzes is in the path argument returns the QuizzesTray', () => {
    const trayObj = getProperTray('/courses/3/quizzes/');
    equal(trayObj.component, QuizzesTray, 'component matches');

    equal(trayObj.label, 'Quizzes Tutorial Tray', 'label matches');
  });

  test('if settings is in the path argument returns the SettingsTray', () => {
    const trayObj = getProperTray('/courses/3/settings/');
    equal(trayObj.component, SettingsTray, 'component matches');

    equal(trayObj.label, 'Settings Tutorial Tray', 'label matches');
  });
  
  test('if files is in the path argument returns the FilesTray', () => {
    const trayObj = getProperTray('/courses/3/files/');
    equal(trayObj.component, FilesTray, 'component matches');

    equal(trayObj.label, 'Files Tutorial Tray', 'label matches');
  });

  test('if users is in the path argument returns the PeopleTray', () => {
    const trayObj = getProperTray('/courses/3/users/');
    equal(trayObj.component, PeopleTray, 'component matches');

    equal(trayObj.label, 'People Tutorial Tray', 'label matches');
  });

  test('if announcements is in the path argument returns the AnnouncementsTray', () => {
    const trayObj = getProperTray('/courses/3/announcements/');
    equal(trayObj.component, AnnouncementsTray, 'component matches');

    equal(trayObj.label, 'Announcements Tutorial Tray', 'label matches');
  });

  test('if gradebook is in the path argument returns the GradesTray', () => {
    const trayObj = getProperTray('/courses/3/gradebook/');
    equal(trayObj.component, GradesTray, 'component matches');

    equal(trayObj.label, 'Gradebook Tutorial Tray', 'label matches');

  });
});
