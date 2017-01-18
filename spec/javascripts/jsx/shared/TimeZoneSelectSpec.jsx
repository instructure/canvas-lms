define([
  'react',
  'jsx/shared/TimeZoneSelect'
], (React, TimeZoneSelect) => {

  const TestUtils = React.addons.TestUtils;

  module('TimeZoneSelect Component');

  test('filterTimeZones', () => {
    const timezones = [{
      name: 'Central'
    }, {
      name: 'Eastern'
    }, {
      name: 'Mountain'
    }, {
      name: 'Pacific'
    }];

    const priorityZones = [{
      name: 'Mountain'
    }];

    const component = TestUtils.renderIntoDocument(
      <TimeZoneSelect timezones={timezones} priority_timezones={priorityZones} />
    );

    const withoutPriority = component.filterTimeZones(timezones, priorityZones);
    const expected = [{
      name: 'Central'
    }, {
      name: 'Eastern'
    }, {
      name: 'Pacific'
    }];

    deepEqual(withoutPriority, expected, 'the filter removed zones with priority');
  });


});