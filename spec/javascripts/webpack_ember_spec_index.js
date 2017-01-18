require('./support/sinon/sinon-1.17.2');
require('./support/sinon/sinon-qunit-amd-1.0.0');

var fixturesDiv = document.createElement('div');
fixturesDiv.id = 'fixtures';
document.body.appendChild(fixturesDiv);
if(!window.ENV) window.ENV = {};

function requireAll(requireContext) {
  return requireContext.keys().map(requireContext);
}

var testsContext = require.context(__dirname + "/../../app/coffeescripts", true, /\.spec$/);
requireAll(testsContext);
