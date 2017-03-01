define([
  'jsx/new_user_tutorial/utils/getProperTray',
  'jsx/new_user_tutorial/trays/HomeTray',
  'jsx/new_user_tutorial/trays/ModulesTray',
  'jsx/new_user_tutorial/trays/PagesTray'
], (getProperTray, HomeTray, ModulesTray, PagesTray) => {
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
});
