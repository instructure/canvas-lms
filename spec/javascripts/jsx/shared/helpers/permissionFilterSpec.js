define([
  'jsx/shared/helpers/permissionFilter'
], (applyPermissions) => {


  QUnit.module('Permissions Filter Helper Function');

  test('Item requires no permissions', () => {
    const items = [
      {
        permissions: []
      }
    ];

    const permissions = {};
    const results = applyPermissions(items, permissions);

    equal(results.length, 1, 'item is not filtered');
  });


  test('User permissions fully match item permissions', () => {
    const items = [
      {
        permissions: ['perm1', 'perm2']
      }
    ];

    const permissions = {
      perm2: true,
      perm1: true
    };

    const results = applyPermissions(items, permissions);

    equal(results.length, 1, 'item is not filetered');
  });


  test('User permissions partially match item permissions', () => {
    const items = [
      {
        permissions: ['perm1', 'perm2']
      }
    ];

    const permissions = {
      perm1: true
    };

    const results = applyPermissions(items, permissions);

    equal(results.length, 0, 'item is filtered');
  });


  test('User permissions fully mismatch required permissions', () => {
    const items = [
      {
        permissions: ['perm1', 'perm2']
      }
    ];

    const permissions = {};
    const results = applyPermissions(items, permissions);

    equal(results.length, 0, 'item is filtered');
  });

});
