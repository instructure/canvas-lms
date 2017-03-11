define([
  'react',
  'react-addons-test-utils',
  'jsx/shared/DatetimeDisplay',
  'timezone'
], (React, TestUtils, DatetimeDisplay, tz) => {

  QUnit.module('DatetimeDisplay');

  test('renders the formatted datetime using the provided format', () => {
    let datetime = (new Date()).toString();
    let component = TestUtils.renderIntoDocument(<DatetimeDisplay datetime={datetime} format='%b' />);
    let formattedTime = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;
    equal(formattedTime, tz.format(datetime, '%b'));
  });

  test('works with a date object', () => {
    let date = new Date(0);
    let component = TestUtils.renderIntoDocument(<DatetimeDisplay datetime={date} format='%b' />);
    let formattedTime = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;
    equal(formattedTime, tz.format(date.toString(), '%b'));
  });

  test('has a default format when none is provided', () => {
    let date = (new Date(0)).toString();
    let component = TestUtils.renderIntoDocument(<DatetimeDisplay datetime={date} />);
    let formattedTime = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;
    equal(formattedTime, tz.format(date, '%c'));
  })
});
