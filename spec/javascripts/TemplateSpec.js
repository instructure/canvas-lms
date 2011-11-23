(function() {
  define(['specs/helpers/testTemplate', 'compiled/Template'], function(_, Template) {
    module('Template');
    test('should create an HTML string from a template', function() {
      var html, template;
      template = new Template('test_template');
      html = template.toHTML({
        foo: 'bar'
      });
      return equal(html, 'bar');
    });
    test('should create a collection of DOM elements', function() {
      var element, template;
      template = new Template('test_template');
      element = template.toElement({
        foo: 'bar'
      });
      return equal(element.html(), 'bar');
    });
    return test('should return the HTML string when called w/o new', function() {
      var html;
      html = Template('test_template', {
        foo: 'bar'
      });
      return equal(html, 'bar');
    });
  });
}).call(this);
