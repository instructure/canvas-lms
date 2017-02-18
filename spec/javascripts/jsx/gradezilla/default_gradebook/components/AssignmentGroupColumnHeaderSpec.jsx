define([
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/gradezilla/default_gradebook/components/AssignmentGroupColumnHeader'
], (React, TestUtils, { mount }, AssignmentGroupColumnHeader) => {
  module('AssignmentGroupColumnHeader - base behavior', {
    setup () {
      this.assignmentGroup = {
        name: 'Assignment Group 1',
        weight: 42.5
      };

      this.renderOutput = mount(<AssignmentGroupColumnHeader assignmentGroup={this.assignmentGroup} weightedGroups />);
    },

    teardown () {
      this.renderOutput.unmount();
    }
  });

  test('renders the assignment group name', function () {
    const actualElements = this.renderOutput.find('.Gradebook__ColumnHeaderDetail');

    equal(actualElements.props().children[0], 'Assignment Group 1');
  });

  test('renders the assignment weight percentage', function () {
    const actualElements = this.renderOutput.find('.Gradebook__ColumnHeaderDetail Typography');

    equal(actualElements.props().children, '42.50% of grade');
  });

  module('AssignmentGroupColumnHeader - non-standard assignment group', {
    setup () {
      this.assignmentGroup = {
        name: 'Assignment Group 1',
        weight: 42.5
      };
    },
  });

  test('renders 0% as the weight percentage when weightedGroups is true but weight is 0', function () {
    this.assignmentGroup.weight = 0;

    const renderOutput = mount(<AssignmentGroupColumnHeader assignmentGroup={this.assignmentGroup} weightedGroups />);
    const actualElements = renderOutput.find('.Gradebook__ColumnHeaderDetail Typography');

    equal(actualElements.props().children, '0.00% of grade');
  });

  test('does not render the weight percentage when weightedGroups is false', function () {
    const renderOutput = mount(<AssignmentGroupColumnHeader assignmentGroup={this.assignmentGroup} />);
    const actualElements = renderOutput.find('.Gradebook__ColumnHeaderDetail Typography');

    equal(actualElements.length, 0);
  });
});
