require('./support/sinon/sinon-1.17.2');
require('./support/sinon/sinon-qunit-amd-1.0.0');

const fixturesDiv = document.createElement('div');
fixturesDiv.id = 'fixtures';
document.body.appendChild(fixturesDiv);

if (!window.ENV) window.ENV = {};
require('react_files/mockFilesENV')

function requireAll(requireContext) {
  return requireContext.keys().map(requireContext);
}

if (__SPEC_FILE) {
  require(__SPEC_FILE)
} else if (__SPEC_DIR) {
  requireAll(require.context(__SPEC_DIR, true, /Spec$/))
} else {
  requireAll(require.context(__dirname + '/../coffeescripts', true, /Spec$/))
  requireAll(require.context(__dirname + '/jsx', true, /Spec$/))
}
