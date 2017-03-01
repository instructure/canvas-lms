define([
  'jsx/new_user_tutorial/utils/getProperTray',
  'jsx/new_user_tutorial/trays/HomeTray',
  'jsx/new_user_tutorial/trays/ModulesTray'
], (getProperTray, HomeTray, ModulesTray) => {
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
});
