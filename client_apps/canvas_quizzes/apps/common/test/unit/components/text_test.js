define(function(require) {
  var React = require('react');
  var Subject = require('jsx!components/text');

  describe('Components.Text', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('should register markup', function() {
      setProps({
        phrase: 'quiz_statistics.test',
        children: React.DOM.p({ children: 'Hello world!' })
      });

      expect(subject.getDOMNode().innerHTML).toMatch('<p>Hello world!</p>');
    });
  });
});