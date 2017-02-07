define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/outcomes/OutcomesActionsPopoverMenu'
], (React, ReactDOM, TestUtils, OutcomesActionsPopoverMenu) => {
  const Simulate = TestUtils.Simulate;

  const fixtures = document.getElementById('fixtures');
  const defaultProps = {
    contextUrlRoot: "test"
  };

  module("OutcomesActionsPopoverMenu", {
    renderComponent(props = {}) {
      let attrs = Object.assign({}, defaultProps, props);
      const element = React.createElement(OutcomesActionsPopoverMenu, attrs);
      return ReactDOM.render(element, fixtures);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(fixtures);
    }
  });

  test("does not render the menu button when user does not have any permissions", function () {
    let popoverMenu = this.renderComponent();
    notOk(ReactDOM.findDOMNode(popoverMenu));
  });

  test("renders the menu button when user has permission to manage outcomes and manage rubrics", function () {
    let popoverMenu = this.renderComponent({
      permissions: {
        manage_rubrics: true
      }
    });
    ok(ReactDOM.findDOMNode(popoverMenu).querySelector("button"));
  });

  // TODO Enable this test once we continue work on OUT-402
  // test("renders the menu button when user has permission to manage outcomes and manage courses", function () {
  //     let popoverMenu = this.renderComponent({
  //         permissions: {
  //             manage_courses: true
  //         }
  //     });
  //     ok(ReactDOM.findDOMNode(popoverMenu).querySelector("button"));
  // });

  test('menu contains "Manage Rubrics" option when user has permission to manage outcomes and manage rubrics', function () {
    let popoverMenu = this.renderComponent({
      permissions: {
        manage_rubrics: true
      }
    });
    Simulate.click(ReactDOM.findDOMNode(popoverMenu).querySelector("button"));
    equal(document.querySelector('[role="menuitem"]').textContent, "Manage Rubrics");
  });

  // TODO Enable this test once we continue work on OUT-402
  // test('menu contains "Add to course..." option when user has permission to manage outcomes and manage rubrics', function () {
  //     let popoverMenu = this.renderComponent({
  //         permissions: {
  //             manage_courses: true
  //         }
  //     });
  //     Simulate.click(ReactDOM.findDOMNode(popoverMenu).querySelector("button"));
  //     equal(document.querySelector('[role="menuitem"]').textContent, "Add to course...");
  // });

  // TODO Enable this test once we continue work on OUT-402
  // test('opens the Add to Course modal when the user clicks the "Add to course..." menu option', function () {
  //     let popoverMenu = this.renderComponent({
  //         permissions: {
  //             manage_courses: true
  //         }
  //     });
  //     var spy = sinon.spy(popoverMenu._addToCourseModal, "open");
  //     Simulate.click(ReactDOM.findDOMNode(popoverMenu).querySelector("button"));
  //     Simulate.click(document.querySelector('[role="menuitem"]'));
  //     ok(spy.calledOnce);
  // });
});
