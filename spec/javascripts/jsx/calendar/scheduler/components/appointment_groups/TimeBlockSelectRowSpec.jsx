define([
  'jquery',
  'react',
  'react-addons-test-utils',
  'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelectRow',
  'timezone/Europe/London',
  'timezone',
  'helpers/fakeENV',
  'jquery.instructure_date_and_time'
], ($, React, TestUtils, TimeBlockSelectRow, london, tz, fakeENV) => {
  let props;
  let tzSnapshot;

  QUnit.module('TimeBlockSelectRow', {
    setup() {
      tzSnapshot = tz.snapshot()
      // set local timezone to UTC
      tz.changeZone(london, 'Europe/London')
      // set user profile timezone to EST (UTC-4)
      fakeENV.setup({ TIMEZONE: 'America/Detroit' })

      props = {
        timeData: {
          date: new Date('2016-10-28T19:00:00.000Z'),
          startTime: new Date('2016-10-28T19:00:00.000Z'),
          endTime: new Date('2016-10-28T19:30:00.000Z')
        },
        setData() {},
        handleDelete() {},
        onBlur() {}
      };
    },
    teardown() {
      props = null;
      tz.restore(tzSnapshot)
      fakeENV.teardown()
    }
  });

  test('componentDidMount sets up the date and time fields', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    const fields = TestUtils.scryRenderedDOMComponentsWithClass(component, 'datetime_field_enabled');
    equal(fields.length, 3);
  });

  test('componentDidMount with readOnly prop disables the datepicker button', () => {
    props.readOnly = true;
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    ok(component.date.nextSibling.hasAttribute('disabled'));
  });

  test('render does not render a delete button when readOnly prop is provided', () => {
    props.readOnly = true;
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    ok(!component.deleteBtn);
  });

  test('render renders out disabled inputs when readOnly prop is true', () => {
    props.readOnly = true;
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    const inputs = TestUtils.scryRenderedDOMComponentsWithTag(component, 'input');
    const disabled = inputs.filter(input => input.hasAttribute('disabled'));
    equal(disabled.length, 3);
  });

  test('render renders out fudged dates for timezones', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    const inputs = TestUtils.scryRenderedDOMComponentsWithTag(component, 'input');
    equal(inputs[1].value, ' 8:00pm')
    equal(inputs[2].value, ' 8:30pm')
  })

  test('handleDelete calls props.handleDelete passing the slotEventId', () => {
    props.handleDelete = sinon.spy();
    props.slotEventId = '123';
    const fakeEvent = {
      preventDefault () {}
    };
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    component.handleDelete(fakeEvent);
    ok(props.handleDelete.calledWith('123'));
  });

  test('handleFieldBlur calls setData', () => {
    props.setData = sinon.spy();
    props.slotEventId = '123';
    const fakeEvent = {
      target: {}
    };
    const component = TestUtils.renderIntoDocument(<TimeBlockSelectRow {...props} />);
    component.handleFieldBlur(fakeEvent);
    equal(props.setData.args[0][0], '123');
    deepEqual(Object.keys(props.setData.args[0][1]), ['date', 'startTime', 'endTime']);
  });

  test('handleFieldBlur calls onBlur when non-blank and when the target row is the last', () => {
    const firstOnBlur = sinon.spy();
    props.onBlur = sinon.spy();
    class TestComponent extends React.Component {
      render () {
        return (
          <div>
            <TimeBlockSelectRow slotEventId="1" {...props} onBlur={firstOnBlur} />
            <TimeBlockSelectRow slotEventId="2" {...props} />
          </div>
        );
      }
    }
    const component = TestUtils.renderIntoDocument(<TestComponent />);
    const timeBlockRows = TestUtils.scryRenderedComponentsWithType(component, TimeBlockSelectRow);
    const fakeEvent = {
      target: TestUtils.findRenderedDOMComponentWithClass(timeBlockRows[1], 'TimeBlockSelectorRow__Date')
    };
    timeBlockRows[1].handleFieldBlur(fakeEvent);
    ok(props.onBlur.called);
    ok(!firstOnBlur.called);
  });
});
