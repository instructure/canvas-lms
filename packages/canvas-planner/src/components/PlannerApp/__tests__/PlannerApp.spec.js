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
import moment from 'moment-timezone';
import MockDate from 'mockdate';
import { shallow, mount } from 'enzyme';
import { PlannerApp } from '../index';

const TZ = 'Asia/Tokyo';

const getDefaultValues = (overrides) => {
  const days = [moment.tz(TZ).add(0, 'day'), moment.tz(TZ).add(1, 'day'), moment.tz(TZ).add(2, 'day')];
  return Object.assign({}, {
    days: days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]),
    timeZone: TZ,
    changeDashboardView () {},
    isCompletelyEmpty: false,
  }, overrides);
};

beforeAll (() => {
  MockDate.set(moment.tz('2017-04-24', TZ));
});

afterAll (() => {
  MockDate.reset();
  jest.restoreAllMocks();
});

describe('PlannerApp', () => {
  it('renders base component', () => {
    const wrapper = shallow(
      <PlannerApp {...getDefaultValues()} />
    );
    expect(wrapper).toMatchSnapshot();
  });

  it('renders empty component with no assignments', () => {
    var opts = getDefaultValues();
    opts.days = [];
    const wrapper = shallow(
      <PlannerApp {...opts}/>
    );
    expect(wrapper).toMatchSnapshot();
  });

  it('always renders today and tomorrow when only items are in the future', () => {
    let days = [moment.tz(TZ).add(+5, 'day')];
    days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
    const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
    expect(wrapper).toMatchSnapshot();
  });

  it('only renders today when the only item is today', () => {
    // because we don't know if we have all the items for tomorrow yet.
    let days = [moment.tz(TZ)];
    days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
    const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
    expect(wrapper).toMatchSnapshot();
  });

  it('shows only the loading component when the isLoading prop is true', () => {
    const wrapper = shallow(
      <PlannerApp
        {...getDefaultValues()}
        isLoading={true}
      />
    );
    expect(wrapper).toMatchSnapshot();
  });

  it('shows the loading past indicator when loadingPast prop is true', () => {
    const wrapper = shallow(
      <PlannerApp
        {...getDefaultValues()}
        loadingPast={true}
      />
    );
    expect(wrapper).toMatchSnapshot();
  });

  it('renders loading past spinner when loading past and there are no future items', () => {
    const wrapper = shallow(
      <PlannerApp
        days={[]}
        timeZone="UTC"
        changeDashboardView={() => {}}
        firstNewActivityDate={moment().add(-1, 'days')}
        loadingPast
      />);
      expect(wrapper).toMatchSnapshot();
  });

  it('notifies the UI to perform dynamic updates', () => {
    const mockUpdate = jest.fn();
    const wrapper = shallow(<PlannerApp
      {...getDefaultValues({isLoading: true})}
      triggerDynamicUiUpdates={mockUpdate} />,
      {lifecycleExperimental: true}); // so componentDidUpdate gets called on setProps
    wrapper.setProps({isLoading: false});
    expect(mockUpdate).toHaveBeenCalledTimes(1);
    expect(mockUpdate).toHaveBeenCalledWith(0);
  });



  it('shows load prior items button when there is more to load', () => {
    const wrapper = shallow(<PlannerApp {...getDefaultValues()} />);
    expect(wrapper.find('ShowOnFocusButton')).toHaveLength(1);
  });

  it('does not show load prior items button when all past items are loaded', () => {
    const wrapper = shallow(<PlannerApp {...getDefaultValues()} allPastItemsLoaded />);
    expect(wrapper.find('ShowOnFocusButton')).toHaveLength(0);
  });

  describe('focus handling', () => {
    const dae = document.activeElement;
    afterEach(() => {
      if (dae) dae.focus(); // else ?
    });

    it('calls fallbackFocus when the load prior focus button disappears', () => {
      const focusFallback = jest.fn();
      const wrapper = mount(<PlannerApp {...getDefaultValues()}
        days={[]} allPastItemsLoaded={false} focusFallback={focusFallback} />);
      const button = wrapper.find('ShowOnFocusButton button');
      button.getDOMNode().focus();
      wrapper.setProps({allPastItemsLoaded: true});
      expect(focusFallback).toHaveBeenCalled();
    });
  });

  describe('empty day calculation', () => {
    it('only renders days with items in the past', () => {
      let days = [moment.tz(TZ).add(-6, 'day'), moment.tz(TZ).add(-5, 'day'), moment.tz(TZ).add(-4, 'day')];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      days[1][1] = [];  // no items 4 days ago
      const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(wrapper).toMatchSnapshot();
    });

    it('always renders yesterday, today and tomorrow', () => {
      let days = [moment.tz(TZ).add(-5, 'day'), moment.tz(TZ).add(+5, 'day')];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(wrapper).toMatchSnapshot();
    });

    it('renders 2 consecutive empty days in the future as empty days', () => {
      let days = [moment.tz(TZ).add(0, 'day'), moment.tz(TZ).add(1, 'day'), moment.tz(TZ).add(4, 'day')];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(wrapper).toMatchSnapshot();
    });

    it('merges 3 consecutive empty days in the future', () => {
      let days = [moment.tz(TZ).add(0, 'day'), moment.tz(TZ).add(1, 'day'), moment.tz(TZ).add(5, 'day')];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(wrapper).toMatchSnapshot();
    });

    it('does not render an empty tomorrow when tomorrow may only be partially loaded', () => {
      let days = [moment.tz(TZ).add(0, 'day')];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      const wrapper = shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(wrapper).toMatchSnapshot();
    });

    it('empty days internals are correct', () => {
      const countSpy = jest.spyOn(PlannerApp.prototype, 'countEmptyDays');
      const emptyDaysSpy = jest.spyOn(PlannerApp.prototype, 'renderEmptyDays');
      const emptyDayStretchSpy = jest.spyOn(PlannerApp.prototype, 'renderEmptyDayStretch');
      const oneDaySpy = jest.spyOn(PlannerApp.prototype, 'renderOneDay');
      let days = [
        moment.tz(TZ).add(0, 'day'),
        moment.tz(TZ).add(1, 'day'),
        moment.tz(TZ).add(3, 'day'),
        moment.tz(TZ).add(6, 'day'),
        moment.tz(TZ).add(10, 'day'),
        moment.tz(TZ).add(14, 'day'),
      ];
      days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]]);
      shallow(<PlannerApp {...getDefaultValues({days})} />);
      expect(countSpy).toHaveBeenCalledTimes(4);            // each time we run into an empty slot
      expect(emptyDayStretchSpy).toHaveBeenCalledTimes(2);  // each time we find >2 consecutive empty days
      expect(emptyDaysSpy).toHaveBeenCalledTimes(2);        // each time we find <3 consecutive empty days
      expect(oneDaySpy).toHaveBeenCalledTimes(6 + 3); // each time we find a day with items + a day with no items
    });
  });
});
