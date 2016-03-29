React = require('react/addons');
TestUtils = React.addons.TestUtils;
ReactTray = React.createFactory(require('../lib/main'));

assert = require('assert');
ok = assert.ok;
equal = assert.equal;
strictEqual = assert.strictEqual;
throws = assert.throws;

var _currentDiv = null;

renderTray = function (props, children, callback) {
  _currentDiv = document.createElement('div');
  document.body.appendChild(_currentDiv);
  return React.render(ReactTray(props, children), _currentDiv, callback);
}

unmountTray = function () {
  React.unmountComponentAtNode(_currentDiv);
  document.body.removeChild(_currentDiv);
  _currentDiv = null;
};
