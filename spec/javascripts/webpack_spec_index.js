require('./support/sinon/sinon-qunit-1.0.0');
require('vendor/ie11-polyfill.js')

const fixturesDiv = document.createElement('div');
fixturesDiv.id = 'fixtures';
document.body.appendChild(fixturesDiv);

if (!window.ENV) window.ENV = {};
require('../coffeescripts/react_files/mockFilesENV.coffee')

function requireAll(requireContext) {
  return requireContext.keys().map(requireContext);
}

if (__SPEC_FILE) {
  require(__SPEC_FILE)
} else if (__SPEC_DIR) {
  requireAll(require.context(__SPEC_DIR, true, /Spec$/))
} else {
  requireAll(require.context(__dirname + '/../coffeescripts', true, /Spec.coffee$/))
  requireAll(require.context(__dirname + '/jsx', true, /Spec$/))
}
