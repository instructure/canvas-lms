define(function(require) {
  var Subject = require('jsx!views/session');

  describe('Views::Session', function() {
    var suite = reactRouterSuite(this, Subject, {});

    suite.stubRoutes([
      { name: "answer_matrix", path: "/doesnt_matter" }
    ]);

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should show nothing when unfocused', function() {
      subject.setProps(
        {
          accessibilityWarningFocused: false
        }
      );
      expect(
        subject
          .getDOMNode()
          .getElementsByClassName('ic-QuizInspector__accessibility-warning screenreader-only')
          .length
      ).toEqual(1);
    });
  });
});