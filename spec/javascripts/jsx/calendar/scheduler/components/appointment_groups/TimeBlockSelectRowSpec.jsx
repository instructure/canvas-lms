define([
  'jquery',
  'react',
  'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelectRow',
], ($, React, TimeBlockSelectRow) => {
  const TestUtils = React.addons.TestUtils;

  let props;

  module('TimeBlockSelectRow', {
    setup () {
      props = {
        timeData: {
          date: new Date(),
          startTime: new Date(),
          endTime: new Date()
        },
        setData () {},
        handleDelete () {},
        onBlur () {}
      };
    },
    teardown () {
      props = null;
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
