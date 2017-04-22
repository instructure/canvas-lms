//
// Copyright (C) 2017 Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/gradezilla/individual-gradebook/components/GradebookSelector'
], (React, ReactDOM, { mount }, GradebookSelector) => {
  QUnit.module('GradebookSelector', {
    setup () {
      this.setLocationStub = this.stub(GradebookSelector.prototype, 'setLocation');
      this.wrapper = mount(
        <GradebookSelector
          courseUrl="http://someUrl/"
          learningMasteryEnabled
          navigate={() => {}}
        />
      );
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('#selectDefaultGradebook calls setLocation', function () {
    this.wrapper.find('select').simulate('change', { target: { value: 'default-gradebook' } });
    const url = `${this.wrapper.props().courseUrl}/gradebook/change_gradebook_version?version=gradezilla`;
    ok(this.setLocationStub.withArgs(url).calledOnce);
  });

  test('#selectGradeHistory calls setLocation', function () {
    this.wrapper.find('select').simulate('change', { target: { value: 'grade-history' } });
    const url = `${this.wrapper.props().courseUrl}/gradebook/history`;
    ok(this.setLocationStub.withArgs(url).calledOnce);
  });

  QUnit.module('Switching between ic-tabs', {
    setup () {
      const ICTabs = props =>
        <ic-tabs>
          <ic-tab onClick={props.firstOnClick} />
          <ic-tab onClick={props.secondOnClick} />
        </ic-tabs>;

      ICTabs.propTypes = {
        firstOnClick: React.PropTypes.func.isRequired,
        secondOnClick: React.PropTypes.func.isRequired,
      };

      this.firstOnClickStub = this.stub();
      this.secondOnClickStub = this.stub();
      const ICTabsProps = {
        firstOnClick: this.firstOnClickStub,
        secondOnClick: this.secondOnClickStub
      };
      const element = React.createElement(ICTabs, ICTabsProps);
      this.fixtures = document.getElementById('fixtures');
      ReactDOM.render(element, this.fixtures);
      this.wrapper = mount(
        <GradebookSelector
          courseUrl="http://someUrl/"
          learningMasteryEnabled
          navigate={() => {}}
        />
      );
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(this.fixtures);
      this.wrapper.unmount();
    }
  });

  test('#selectIndividualGradebook calls click on the first ic-tab', function () {
    this.wrapper.find('select').simulate('change', { target: { value: 'individual-gradebook' } });
    ok(this.firstOnClickStub.calledOnce);
  });

  test('#selectLearningMastery calls click on the second ic-tab', function () {
    this.wrapper.find('select').simulate('change', { target: { value: 'learning-mastery' } });
    ok(this.secondOnClickStub.calledOnce);
  });

  test('defaults to Individual View', function () {
    equal(this.wrapper.find('select').node.value, 'individual-gradebook');
  });

  test('clicking on learning mastery changes the selected value to learning mastery', function () {
    this.wrapper.find('select').simulate('change', { target: { value: 'learning-mastery' } });
    equal(this.wrapper.find('select').node.value, 'learning-mastery');
  });

  test('clicking on individual view changes the selected value to individual view', function () {
    // by default individual-gradebook is selected
    this.wrapper.find('select').simulate('change', { target: { value: 'learning-mastery' } });
    this.wrapper.find('select').simulate('change', { target: { value: 'individual-gradebook' } });
    equal(this.wrapper.find('select').node.value, 'individual-gradebook');
  });


  QUnit.module('Menu Items Rendered with Learning Mastery Enabled', {
    setup () {
      this.wrapper = mount(
        <GradebookSelector
          courseUrl="http://someUrl/"
          learningMasteryEnabled
          navigate={() => {}}
        />
      );
      this.menuItems = this.wrapper.find('option').nodes;
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('Individual View is first', function () {
    equal(this.menuItems[0].textContent, 'Individual View');
  });

  test('Learning Mastery is second', function () {
    equal(this.menuItems[1].textContent, 'Learning Mastery…');
  });

  test('Gradebook is third', function () {
    equal(this.menuItems[2].textContent, 'Gradebook…');
  });


  test('Grade History is fourth', function () {
    equal(this.menuItems[3].textContent, 'Grade History…');
  });

  QUnit.module('Menu Items Rendered with Learning Mastery Disabled', {
    setup () {
      this.wrapper = mount(
        <GradebookSelector
          courseUrl="http://someUrl/"
          learningMasteryEnabled={false}
          navigate={() => {}}
        />
      );
      this.menuItems = this.wrapper.find('option').nodes;
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('Individual Gradebook is first', function () {
    equal(this.menuItems[0].textContent, 'Individual View');
  });

  test('Gradebook is second', function () {
    equal(this.menuItems[1].textContent, 'Gradebook…');
  });

  test('Grade History Menu Item is third in the PopoverMenu', function () {
    equal(this.menuItems[2].textContent, 'Grade History…');
  });
});
