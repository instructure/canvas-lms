// Creates a DOM element that ReactSuite tests will use to mount the subject
// in. Although jasmine_react does that automatically on the start of each
// ReactSuite, we will prepare it before-hand and expose it to jasmine.fixture
// if you need to access directly.
require([ 'jasmine_react' ], function(ReactSuite) {
  console.log('Preparing jasmine DOM fixture at `jasmine.fixture`');

  jasmine.fixture = ReactSuite.createDOMFixture();
});