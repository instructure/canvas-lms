define([
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/gradezilla/default_gradebook/components/AssignmentColumnHeader'
], (React, TestUtils, { mount }, AssignmentColumnHeader) => {
  module('AssignmentColumnHeader - base behavior', {
    setup () {
      this.assignment = {
        id: '1',
        htmlUrl: 'http://assignment_htmlUrl',
        invalid: false,
        muted: false,
        name: 'Assignment #1',
        omitFromFinalGrade: false,
        pointsPossible: 13
      };

      this.renderOutput = mount(<AssignmentColumnHeader assignment={this.assignment} />);
    },

    teardown () {
      this.renderOutput.unmount();
    }
  });

  test('renders the assignment name in a link', function () {
    const actualElements = this.renderOutput.find('.assignment-name Link');
    const expectedLinkProps = {
      children: [
        undefined,
        this.assignment.name
      ],
      title: undefined,
      href: this.assignment.htmlUrl
    };

    equal(actualElements.length, 1);
    deepEqual(actualElements.props(), expectedLinkProps);
  });

  test('renders the points possible', function () {
    const actualElements = this.renderOutput.find('.assignment-points-possible');

    equal(actualElements.length, 1);
    equal(actualElements.props().children, 'Out of 13');
  });

  test('renders a PopoverMenu', function () {
    const actualElements = this.renderOutput.find('PopoverMenu');

    equal(actualElements.length, 1);
  });

  test('renders an IconMoreSolid inside the PopoverMenu', function () {
    const actualElements = this.renderOutput.find('PopoverMenu IconMoreSolid');

    equal(actualElements.length, 1)
  });

  test('renders a title for the More icon based on the assignment name', function () {
    const actualElements = this.renderOutput.find('PopoverMenu IconMoreSolid');

    equal(actualElements.props().title, 'Assignment #1 Options');
  });

  module('AssignmentColumnHeader - non-standard assignment', {
    setup () {
      this.assignment = {
        id: '1',
        htmlUrl: 'http://assignment_htmlUrl',
        invalid: false,
        muted: false,
        name: 'Assignment #1',
        omitFromFinalGrade: false,
        pointsPossible: 13
      };
    }
  });

  test('does not render points possible when the assignment has no possible points', function () {
    this.assignment.pointsPossible = undefined;

    this.renderOutput = mount(<AssignmentColumnHeader assignment={this.assignment} />);

    const actualElements = this.renderOutput.find('.assignment-points-possible');

    equal(actualElements.length, 0);
  });

  test('renders a muted icon when the assignment is muted', function () {
    this.assignment.muted = true;

    this.renderOutput = mount(<AssignmentColumnHeader assignment={this.assignment} />);

    const actualLinkElements = this.renderOutput.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconMutedSolid');
    const expectedLinkTitle = 'This assignment is muted';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });

  test('renders a warning icon when the assignment does not count towards final grade', function () {
    this.assignment.omitFromFinalGrade = true;

    this.renderOutput = mount(<AssignmentColumnHeader assignment={this.assignment} />);

    const actualLinkElements = this.renderOutput.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconWarningSolid');
    const expectedLinkTitle = 'This assignment does not count toward the final grade';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });

  test('renders a warning icon when the assignment is invalid', function () {
    this.assignment.invalid = true;

    this.renderOutput = mount(<AssignmentColumnHeader assignment={this.assignment} />);

    const actualLinkElements = this.renderOutput.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconWarningSolid');
    const expectedLinkTitle = 'Assignments in this group have no points possible and cannot be included in grade calculation';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });
});
