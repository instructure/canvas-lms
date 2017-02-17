define([
  'jquery',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelector',
], ($, React, ReactDOM, TestUtils, TimeBlockSelector) => {
  let props;

  QUnit.module('TimeBlockSelector', {
    setup () {
      props = {
        timeData: [],
        onChange () {}
      };
    },
    teardown () {
      props = null;
    }
  });

  test('it renders', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    ok(component);
  });

  test('handleSlotDivision divides slots and adds new rows to the selector', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    const domNode = ReactDOM.findDOMNode(component);
    $('.TimeBlockSelector__DivideSection-Input', domNode).val(60);
    const newRow = component.state.timeBlockRows[0];
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00');
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00');
    component.setState({
      timeBlockRows: [newRow]
    });
    component.handleSlotDivision();
    equal(component.state.timeBlockRows.length, 6);
  });

  test('handleSlotAddition adds new time slot with time', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    const newRow = component.state.timeBlockRows[0];
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00');
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00');
    equal(component.state.timeBlockRows.length, 1);
    component.addRow(newRow);
    equal(component.state.timeBlockRows.length, 2);
  });

  test('handleSlotAddition adds new time slot without time', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    equal(component.state.timeBlockRows.length, 1);
    component.addRow();
    equal(component.state.timeBlockRows.length, 2);
  })

  test('handleSlotDeletion delete a time slot with time', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    const newRow = component.state.timeBlockRows[0];
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00');
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00');
    component.addRow(newRow)
    equal(component.state.timeBlockRows.length, 2)
    component.deleteRow(component.state.timeBlockRows[1].slotEventId)
    equal(component.state.timeBlockRows.length, 1)
  })

  test('handleSetData setting time data', () => {
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    const newRow = component.state.timeBlockRows[0];
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00');
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00');
    component.addRow(newRow)
    newRow.timeData.startTime = new Date('Oct 26 2016 11:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 16:00')
    component.handleSetData(component.state.timeBlockRows[1].slotEventId, newRow)
    deepEqual(component.state.timeBlockRows[0].timeData.endTime, new Date('Oct 26 2016 16:00'))
  })

  test('calls onChange when there are modifications made', () => {
    props.onChange = sinon.spy();
    const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />);
    const domNode = ReactDOM.findDOMNode(component);
    $('.TimeBlockSelector__DivideSection-Input', domNode).val(60);
    const newRow = component.state.timeBlockRows[0];
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00');
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00');
    component.setState({
      timeBlockRows: [newRow]
    });
    ok(props.onChange.called);
  })
});
