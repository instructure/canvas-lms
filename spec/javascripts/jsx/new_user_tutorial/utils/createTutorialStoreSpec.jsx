define([
  'jsx/new_user_tutorial/utils/createTutorialStore'
], (createTutorialStore) => {
  QUnit.module('createTutorialStore test');

  test('sets isCollapsed to true initially', () => {
    const store = createTutorialStore();
    ok(store.getState().isCollapsed);
  });
});
