/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react';
import { shallow, mount } from 'enzyme';
import { PlannerHeader } from '../index';


function defaultProps (options) {
  return {
    courses: [{id: "1", shortName: "Course Short Name", informStudentsOfOverdueSubmissions: true}],
    opportunities: {
      items: [{id: "1", course_id: "1", due_at: "2017-03-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"}],
      nextUrl: null
    },
    getInitialOpportunities: () => {},
    getNextOpportunities: () => {},
    savePlannerItem: () => {},
    locale: 'en',
    timeZone: 'America/Denver',
    deletePlannerItem: () => {},
    dismissOpportunity: () => {},
    clearUpdateTodo: () => {},
    startLoadingGradesSaga: () => {},
    ariaHideElement: document.createElement('div'),
    loading: {
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      allOpportunitiesLoaded: false,
      setFocusAfterLoad: false,
      firstNewDayKey: null,
      futureNextUrl: null,
      pastNextUrl: null,
      seekingNewActivity: false,
      loadingGrades: false,
      gradesLoaded: false,
    },
    todo: {
      updateTodoItem: null
    },
    ...options,
  };
}

// These are terrible, but the property selectors weren't working for me
// (even though the children property apparently works)
function findEditTray (wrapper) {
  return wrapper.find('Tray').at(0);
}

function findGradesTray (wrapper) {
  return wrapper.find('Tray').at(1);
}

it('renders the base component correctly with buttons and trays', () => {
  const wrapper = shallow(
    <PlannerHeader {...defaultProps()} />
  );
  expect(wrapper).toMatchSnapshot();
});

it('toggles the new item tray', () => {
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} />
  );
  const button = wrapper.find('[children="Add To Do"]');
  button.simulate('click');
  expect(findEditTray(wrapper).props().open).toEqual(true);
  button.simulate('click');
  expect(findEditTray(wrapper).props().open).toEqual(false);
});

it('sends focus back to the add new item button', () => {
  const mockCancel = jest.fn();
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} cancelEditingPlannerItem={mockCancel}/>
  );
  wrapper.instance().toggleUpdateItemTray();
  wrapper.instance().handleCancelPlannerItem();
  expect(mockCancel).toHaveBeenCalled();
});

it('calls getInitialOpportunities when component is mounted', () => {
  let tempProps = defaultProps();
  const mockDispatch = jest.fn();
  tempProps.getInitialOpportunities = mockDispatch;
  mount(
    <PlannerHeader {...tempProps} />
  );
  expect(tempProps.getInitialOpportunities).toHaveBeenCalled();
});

it('toggles aria-hidden on the ariaHideElement when opening the opportunities popover', () => {
  const fakeElement = document.createElement('div');
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} ariaHideElement={fakeElement} />
  );
  const button = wrapper.find('PopoverTrigger').find('Button');
  button.simulate('click');
  expect(fakeElement.getAttribute('aria-hidden')).toBe('true');
  button.simulate('click');
  expect(fakeElement.getAttribute('aria-hidden')).toBe(null);
});

it('toggles aria-hidden on the ariaHideElement when opening the add to do item tray', () => {
  const fakeElement = document.createElement('div');
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} ariaHideElement={fakeElement} />
  );

  const button = wrapper.find('IconPlusLine').parent();

  button.simulate('click');
  expect(fakeElement.getAttribute('aria-hidden')).toBe('true');
  button.simulate('click');
  expect(fakeElement.getAttribute('aria-hidden')).toBe(null);
});

it('renders the tray with the name of an existing item when provided', () => {
  const wrapper = shallow(
    <PlannerHeader {...defaultProps({todo: {updateTodoItem: {title: 'abc'}}})} />
  );
  expect(findEditTray(wrapper).prop('label')).toBe('Edit abc');
});

it('calls clearUpdateTodo when closing the tray', () => {
  const fakeClearFunc = jest.fn();
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} clearUpdateTodo={fakeClearFunc} />
  );
  wrapper.instance().toggleUpdateItemTray();
  wrapper.instance().noteBtnOnClose();
  expect(fakeClearFunc).toHaveBeenCalled();
});

it('does not call getNextOpportunities when component has 12 opportunities', () => {
  const mockDispatch = jest.fn();
  const props = defaultProps();
  props.courses = [
    {id: "1", shortName: "Course Short Name"},
    {id: "2", shortName: "Course Other Name"},
    {id: "3", shortName: "Course Big Name"}
  ];

  props.opportunities.items = [
    {id: "1", course_id: "1", due_at: "2017-03-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "2", course_id: "2", due_at: "2017-04-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "3", course_id: "3", due_at: "2017-05-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "4", course_id: "1", due_at: "2017-06-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "5", course_id: "2", due_at: "2017-07-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "6", course_id: "3", due_at: "2017-08-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "7", course_id: "1", due_at: "2017-09-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "8", course_id: "2", due_at: "2017-10-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "9", course_id: "1", due_at: "2017-15-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "11", course_id: "2", due_at: "2017-16-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "12", course_id: "1", due_at: "2017-12-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "10", course_id: "2", due_at: "2017-17-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"}
  ];

  props.loading = {
    allPastItemsLoaded: false,
    allFutureItemsLoaded: false,
    allOpportunitiesLoaded: false,
    setFocusAfterLoad: false,
    firstNewDayKey: null,
    futureNextUrl: null,
    pastNextUrl: null,
    seekingNewActivity: false,
  };

  props.todo = {};

  props.getNextOpportunities = mockDispatch;
  const wrapper = shallow(
    <PlannerHeader {...props} />
  );

  wrapper.setProps(props);
  expect(props.getNextOpportunities).not.toHaveBeenCalled();
});

it('does call getNextOpportunities when component has 9 opportunities', () => {
  const mockDispatch = jest.fn();
  const props = defaultProps();
  props.courses = [
    {id: "1", shortName: "Course Short Name"},
    {id: "2", shortName: "Course Other Name"},
    {id: "3", shortName: "Course Big Name"}
  ];

  props.opportunities.items = [
    {id: "1", course_id: "1", due_at: "2017-03-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "2", course_id: "2", due_at: "2017-04-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "3", course_id: "3", due_at: "2017-05-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "4", course_id: "1", due_at: "2017-06-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "5", course_id: "2", due_at: "2017-07-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "6", course_id: "3", due_at: "2017-08-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "7", course_id: "1", due_at: "2017-09-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "8", course_id: "2", due_at: "2017-10-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "9", course_id: "1", due_at: "2017-15-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
  ];

  props.loading = {
    allPastItemsLoaded: false,
    allFutureItemsLoaded: false,
    allOpportunitiesLoaded: false,
    setFocusAfterLoad: false,
    firstNewDayKey: null,
    futureNextUrl: null,
    pastNextUrl: null,
    seekingNewActivity: false,
  };
  props.todo = {};

  props.getNextOpportunities = mockDispatch;
  const wrapper = shallow(
    <PlannerHeader {...props} />
  );

  wrapper.setProps(props);
  expect(props.getNextOpportunities).toHaveBeenCalled();
});

it('opens tray if todo update item props is set', () => {
  const mockDispatch = jest.fn();
  const props = defaultProps();
  props.courses = [
    {id: "1", shortName: "Course Short Name"},
    {id: "2", shortName: "Course Other Name"},
    {id: "3", shortName: "Course Big Name"}
  ];

  props.opportunities.items = [
    {id: "1", course_id: "1", due_at: "2017-03-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "2", course_id: "2", due_at: "2017-04-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "3", course_id: "3", due_at: "2017-05-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "4", course_id: "1", due_at: "2017-06-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "5", course_id: "2", due_at: "2017-07-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "6", course_id: "3", due_at: "2017-08-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "7", course_id: "1", due_at: "2017-09-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "8", course_id: "2", due_at: "2017-10-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "9", course_id: "1", due_at: "2017-15-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "11", course_id: "2", due_at: "2017-16-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "12", course_id: "1", due_at: "2017-12-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "10", course_id: "2", due_at: "2017-17-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"}
  ];

  props.todo = {
    updateTodoItem: {
      id: 10
    }
  };

  props.updateTodoItem = true;

  props.getNextOpportunities = mockDispatch;
  const wrapper = shallow(
    <PlannerHeader {...props} />
  );

  wrapper.setProps(props);
  expect(wrapper.state().trayOpen).toEqual(true);
});

it('shows only 10 opportunities badge when we over 10 items', () => {
  const props = defaultProps();
  props.courses = [
    {id: "1", shortName: "Course Short Name"},
    {id: "2", shortName: "Course Other Name"},
    {id: "3", shortName: "Course Big Name"}
  ];

  props.opportunities.items = [
    {id: "1", course_id: "1", due_at: "2017-03-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "2", course_id: "2", due_at: "2017-04-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "3", course_id: "3", due_at: "2017-05-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "4", course_id: "1", due_at: "2017-06-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "5", course_id: "2", due_at: "2017-07-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "6", course_id: "3", due_at: "2017-08-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "7", course_id: "1", due_at: "2017-09-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "8", course_id: "2", due_at: "2017-10-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "9", course_id: "3", due_at: "2017-13-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "10", course_id: "1", due_at: "2017-14-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "11", course_id: "2", due_at: "2017-15-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
    {id: "12", course_id: "3", due_at: "2017-16-09T20:40:35Z", html_url: "http://www.non_default_url.com", name: "learning object title"},
  ];

  const fakeElement = document.createElement('div');
  const wrapper = mount(
    <PlannerHeader {...props} ariaHideElement={fakeElement} />
  );
  wrapper.setProps(props);
  expect(wrapper.find('Badge').filterWhere((item) => {
    return item.prop('count') === 10; //src undefined
  }).length).toEqual(1);
});


it('edits new item in open tray', () => {
  const openEditingPlannerItem = jest.fn();
  const todo1 = {title: 'todo1'};
  const todo2 = {title: 'todo2'};
  // Because Tray renders its contents (UpdateItemTray) somewhere else in the DOM,
  // if we mount(), we won't be able to find it to check its properties
  const wrapper = shallow(
    <PlannerHeader {...defaultProps()} openEditingPlannerItem={openEditingPlannerItem} />
  );

  // edit a PlannerItem
  wrapper.setProps({...defaultProps({todo: {updateTodoItem: todo1}})});
  expect(findEditTray(wrapper).prop('open')).toEqual(true);
  expect(wrapper.find('UpdateItemTray').prop('noteItem')).toEqual(todo1);
  expect(openEditingPlannerItem).toHaveBeenCalledTimes(1);

  // edit another PlannerItem in open tray
  wrapper.setProps({...defaultProps({todo: {updateTodoItem: todo2}})});
  expect(findEditTray(wrapper).props().open).toEqual(true);
  expect(wrapper.find('UpdateItemTray').prop('noteItem')).toEqual(todo2);
  expect(openEditingPlannerItem).toHaveBeenCalledTimes(2);
});

it('sets the maxHeight on the Opportunities', () => {
  window.innerHeight = 700; // even though it doesn't actually change the window's size, you can do this.
  const wrapper = shallow(
    <PlannerHeader {...defaultProps()} />
  );
  // since we've shallow rendered, have to stub in the button
  // (if we mount, then the popup isn't reachable from enzyme)
  wrapper.instance().opportunitiesHtmlButton = {
    getBoundingClientRect () {
        return {top: 10, height: 20};
    }
  };
  // triggers a re-render
  wrapper.setState({opportunitiesOpen: true});
  expect(wrapper.find('Animatable(Opportunities)').prop('maxHeight')).toEqual(640);
});

it('leaves the tray in current open state when receiving new empty todo props', () => {
  const wrapper = shallow(
    <PlannerHeader {...defaultProps()} />
  );
  wrapper.instance().toggleUpdateItemTray();
  wrapper.setProps({...defaultProps({todo: {}})});
  expect(findEditTray(wrapper).prop('open')).toBe(true);
});

it('toggles the grades tray', () => {
  const wrapper = mount(
    <PlannerHeader {...defaultProps()} />
  );
  const button = wrapper.find('[children="Show My Grades"]');
  button.simulate('click');
  expect(findGradesTray(wrapper).props().open).toEqual(true);
  button.simulate('click');
  expect(findGradesTray(wrapper).props().open).toEqual(false);
});

it('calls startLoadingGradesSaga when grades are not loaded and the grades tray opens', () => {
  const props = defaultProps();
  props.startLoadingGradesSaga = jest.fn();
  const wrapper = shallow(<PlannerHeader {...props} />);
  wrapper.instance().toggleGradesTray();
  expect(props.startLoadingGradesSaga).toHaveBeenCalled();
});

it('passes loading to the GradesDisplay when grades are loading', () => {
  const props = defaultProps();
  props.loading.loadingGrades = true;
  const wrapper = shallow(<PlannerHeader {...props} />);
  expect(wrapper.find('GradesDisplay').prop('loading')).toBe(true);
});

it('does not start the grades saga when grades are loading', () => {
  const props = defaultProps();
  props.loading.loadingGrades = true;
  props.startLoadingGradesSaga = jest.fn();
  const wrapper = shallow(<PlannerHeader {...props} />);
  wrapper.instance().toggleGradesTray();
  expect(props.startLoadingGradesSaga).not.toHaveBeenCalled();
});

it('does not start the grades saga when grades have been loaded', () => {
  const props = defaultProps();
  props.loading.gradesLoaded = true;
  props.startLoadingGradesSaga = jest.fn();
  const wrapper = shallow(<PlannerHeader {...props} />);
  wrapper.instance().toggleGradesTray();
  expect(props.startLoadingGradesSaga).not.toHaveBeenCalled();
});
