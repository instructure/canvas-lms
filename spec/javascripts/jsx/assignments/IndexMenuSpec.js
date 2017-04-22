define([
  'react',
  'react-addons-test-utils',
  'react-modal',
  'jsx/assignments/IndexMenu',
  'jsx/assignments/actions/IndexMenuActions',
  './createFakeStore',
], (React, TestUtils, Modal, IndexMenu, Actions, createFakeStore) => {
  QUnit.module('AssignmentsIndexMenu')

  const generateProps = (overrides, initialState = {}) => {
    const state = {
      externalTools: [],
      selectedTool: null,
      ...initialState
    };
    return {
      store: createFakeStore(state),
      contextType: 'course',
      contextId: 1,
      setTrigger: () => {},
      registerWeightToggle: () => {},
      ...overrides,
    };
  };

  const renderComponent = (props) => {
    return TestUtils.renderIntoDocument(
      <IndexMenu {...props} />
    );
  };

  const context = {};

  const beforeEach = () => {
    context.sinon = sinon.sandbox.create();
    context.sinon.stub(Actions, 'apiGetLaunches').returns({
      type: 'STUB_API_GET_TOOLS'
    });
  };

  const afterEach = () => {
    context.sinon.restore();
  };

  const testCase = (msg, testFunc) => {
    beforeEach();
    test(msg, testFunc);
    afterEach();
  };

  testCase('renders a dropdown menu trigger and options list', () => {
    const component = renderComponent(generateProps({}));

    const triggers = TestUtils.scryRenderedDOMComponentsWithClass(component, 'al-trigger');
    equal(triggers.length, 1);

    const options = TestUtils.scryRenderedDOMComponentsWithClass(component, 'al-options');
    equal(options.length, 1);
  });

  testCase('renders a LTI tool modal', () => {
    const component = renderComponent(generateProps({}));

    const modals = TestUtils.scryRenderedComponentsWithType(component, Modal);
    equal(modals.length, 1);
  });

  testCase('Modal visibility agrees with state modalIsOpen', () => {
    const component1 = renderComponent(generateProps({}, { modalIsOpen: true }));
    const modal1 = TestUtils.findRenderedComponentWithType(component1, Modal);
    equal(modal1.props.isOpen, true);

    const component2 = renderComponent(generateProps({}, { modalIsOpen: false }));
    const modal2 = TestUtils.findRenderedComponentWithType(component2, Modal);
    equal(modal2.props.isOpen, false);
  });

  testCase('renders no iframe when there is no selectedTool in state', () => {
    const component = renderComponent(generateProps({}, { selectedTool: null }));
    const iframes = TestUtils.scryRenderedDOMComponentsWithTag(component, 'iframe');
    equal(iframes.length, 0);
  });

  testCase('renders iframe when there is a selectedTool in state', () => {
    const component = renderComponent(
      generateProps({}, {
        modalIsOpen: true,
        selectedTool: {
          placements: { course_assignments_menu: { title: 'foo' } },
          definition_id: 100,
        },
      })
    );

    const modal = TestUtils.findRenderedComponentWithType(component, Modal);
    const modalPortal = modal.portal;

    const iframes = TestUtils.scryRenderedDOMComponentsWithTag(modalPortal, 'iframe');
    equal(iframes.length, 1);
  });

  testCase('onWeightedToggle dispatches expected actions', () => {
    const props = generateProps({});
    const store = props.store;
    const component = renderComponent(props);
    const actionsCount = store.dispatchedActions.length;

    component.onWeightedToggle(true);
    equal(store.dispatchedActions.length, actionsCount + 1);
    equal(store.dispatchedActions[actionsCount].type, Actions.SET_WEIGHTED);
    equal(store.dispatchedActions[actionsCount].payload, true);

    component.onWeightedToggle(false);
    equal(store.dispatchedActions.length, actionsCount + 2);
    equal(store.dispatchedActions[actionsCount + 1].type, Actions.SET_WEIGHTED);
    equal(store.dispatchedActions[actionsCount + 1].payload, false);
  });
});
