define([
  'jsx/assignments/actions/IndexMenuActions',
], (Actions) => {
  module('AssignmentsIndexMenuActions')

  test('setModalOpen returns the expected action', () => {
    const expectedAction1 = {
      type: Actions.SET_MODAL_OPEN,
      payload: true,
    };
    const actualAction1 = Actions.setModalOpen(true);
    deepEqual(expectedAction1, actualAction1);

    const expectedAction2 = {
      type: Actions.SET_MODAL_OPEN,
      payload: false,
    };
    const actualAction2 = Actions.setModalOpen(false);
    deepEqual(expectedAction2, actualAction2);
  });

  test('launchTool returns the expected action', () => {
    const tool = { 'foo': 'bar'};
    const expectedAction = {
      type: Actions.LAUNCH_TOOL,
      payload: tool,
    };
    const actualAction = Actions.launchTool(tool);
    deepEqual(expectedAction, actualAction);
  });

  test('setWeighted returns the expected action', () => {
    const expectedAction1 = {
      type: Actions.SET_WEIGHTED,
      payload: true,
    };
    const actualAction1 = Actions.setWeighted(true);
    deepEqual(expectedAction1, actualAction1);

    const expectedAction2 = {
      type: Actions.SET_WEIGHTED,
      payload: false,
    };
    const actualAction2 = Actions.setWeighted(false);
    deepEqual(expectedAction2, actualAction2);
  });
});
