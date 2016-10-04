define([
  'jquery',
  'react',
  'react-dom',
  'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelector',
], ($, React, ReactDOM, TimeBlockSelector) => {
  const TestUtils = React.addons.TestUtils;

  let props;

  module('TimeBlockSelector', {
    setup () {
      props = {
        timeData: []
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
});
