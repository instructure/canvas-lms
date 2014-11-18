define(function(require) {
  var Subject = require('jsx!views/questions/essay');

  describe('Views.Questions.Essay', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('should provide a link to speedgrader', function() {
      setProps({
        speedGraderUrl: 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=10'
      });

      expect('a[href*=speed_grader]').toExist();
      expect(find('a[href*=speed_grader]').innerText).toContain('View in SpeedGrader');
    });
  });
});