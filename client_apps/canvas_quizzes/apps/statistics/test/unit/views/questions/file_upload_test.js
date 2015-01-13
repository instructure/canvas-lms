define(function(require) {
  var Subject = require('jsx!views/questions/file_upload');

  describe('Views.Questions.FileUpload', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should provide a link to download submissions', function() {
      setProps({
        quizSubmissionsZipUrl: 'http://localhost:3000/courses/1/quizzes/8/submissions?zip=1'
      });

      expect('a[href*=zip]').toExist();
      expect(find('a[href*=zip]').innerText).toContain('Download All Files');
    });
  });
});