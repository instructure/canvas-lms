require('./support/sinon/sinon-1.17.2');
require('./support/sinon/sinon-qunit-amd-1.0.0');

var fixturesDiv = document.createElement('div');
fixturesDiv.id = 'fixtures';
document.body.appendChild(fixturesDiv);
if(!window.ENV) window.ENV = {};

require(__dirname + "/../../app/coffeescripts/ember/shared/tests/xhr/fetch_all_pages.spec")
require(__dirname + "/../../app/coffeescripts/ember/shared/tests/components/ic_submission_download_dialog.spec")

require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/components/assignment_group_grades.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/components/custom_column_cell.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/components/grading_cell.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/components/muter.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/controllers/screenreader_gradebook.spec")

require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/grading_cell.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/item_selection.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/muter_component.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/settings.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/sorting.spec")
require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/integration/ungraded.spec")

require(__dirname + "/../../app/coffeescripts/ember/screenreader_gradebook/tests/app.spec")
