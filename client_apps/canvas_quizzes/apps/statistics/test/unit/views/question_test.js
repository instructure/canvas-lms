define(function(require) {
  var Subject = require('jsx!views/question');

  describe('Views.Question', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should show details if "expanded" is truthy', function() {
      setProps({ expanded: true });
      expect(subject.getDOMNode().className).toMatch('with-details');
    });
  });
});