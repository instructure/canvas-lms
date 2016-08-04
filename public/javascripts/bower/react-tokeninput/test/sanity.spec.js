var React = require('react')
var TestUtils = require('react-addons-test-utils')

var Tokeninput = React.createFactory(require('../index'))

describe('Sanity test', function() {

  it ('renders component', function() {
    var tokeninput = Tokeninput({
      selected: [],
      onSelect: function() {},
      onRemove: function() {}
    })
    var instance = TestUtils.renderIntoDocument(tokeninput)
    var ul = TestUtils.findRenderedDOMComponentWithTag(instance, 'ul')
    should.exist(ul)
  })

})
