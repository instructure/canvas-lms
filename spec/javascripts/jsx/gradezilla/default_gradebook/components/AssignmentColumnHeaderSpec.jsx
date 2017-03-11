define([
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/gradezilla/default_gradebook/components/AssignmentColumnHeader'
], (React, TestUtils, { mount }, AssignmentColumnHeader) => {
  const assignmentProp = () => (
    {
      id: '1',
      htmlUrl: 'http://assignment_htmlUrl',
      invalid: false,
      muted: false,
      name: 'Assignment #1',
      omitFromFinalGrade: false,
      pointsPossible: 13,
      submissionTypes: ['online_text_entry'],
      courseId: '42'
    }
  );
  const studentsProp = () => (
    [
      {
        id: '11',
        name: 'Clark Kent',
        isInactive: false,
        submission: {
          score: 7,
          submittedAt: null
        }
      },
      {
        id: '13',
        name: 'Barry Allen',
        isInactive: false,
        submission: {
          score: 8,
          submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
        }
      },
      {
        id: '15',
        name: 'Bruce Wayne',
        isInactive: false,
        submission: {
          score: undefined,
          submittedAt: undefined
        }
      }
    ]
  );

  QUnit.module('AssignmentColumnHeader - base behavior', {
    setup () {
      const props = {
        assignment: assignmentProp(),
        students: studentsProp(),
        submissionsLoaded: true
      };

      this.renderOutput = mount(<AssignmentColumnHeader {...props} />);
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
        assignmentProp().name
      ],
      title: undefined,
      href: assignmentProp().htmlUrl
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

  QUnit.module('AssignmentColumnHeader - Message Students Who Menu', {
    setup () {
      this.props = {
        assignment: assignmentProp(),
        students: studentsProp(),
        submissionsLoaded: true
      };
    },

    teardown () {
      this.renderOutput.unmount();
    }
  });

  test('shows the menu item in an enabled state', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('PopoverMenu').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

    equal(specificMenuItem.textContent, 'Message Students Who');
    notOk(specificMenuItem.parentElement.getAttribute('aria-disabled'));
  });

  test('disables the menu item when submissions are not loaded', function () {
    this.props.submissionsLoaded = false;
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('PopoverMenu').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

    equal(specificMenuItem.parentElement.getAttribute('aria-disabled'), 'true');
  });

  test('clicking the menu item invokes the Message Students Who dialog', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('PopoverMenu').simulate('click');

    const messageStudentsStub = this.stub(window, 'messageStudents');
    const specificMenuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

    specificMenuItem.click();

    ok(messageStudentsStub.calledOnce);
  });

  QUnit.module('AssignmentColumnHeader - non-standard assignment', {
    setup () {
      this.assignment = assignmentProp();

      this.props = {
        assignment: this.assignment,
        students: [],
        submissionsLoaded: false
      }
    }
  });

  test('does not render points possible when the assignment has no possible points', function () {
    this.assignment.pointsPossible = undefined;

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);

    const actualElements = this.renderOutput.find('.assignment-points-possible');

    equal(actualElements.length, 0);
  });

  test('renders a muted icon when the assignment is muted', function () {
    this.assignment.muted = true;

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);

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

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);

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

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);

    const actualLinkElements = this.renderOutput.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconWarningSolid');
    const expectedLinkTitle = 'Assignments in this group have no points possible and cannot be included in grade calculation';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });
});
