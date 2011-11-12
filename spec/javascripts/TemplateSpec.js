(function() {
  define(['js!vendor/jquery-1.6.4.js!order', 'js!vendor/handlebars.vm.js!order', 'js!compiled/Template.js!order', 'js!specs/helpers/TemplateHelper.js!order'], function() {
    module('Template');
    test('should create an HTML string from a template', function() {
      var html, template;
      template = new Template('test');
      html = template.toHTML({
        foo: 'bar'
      });
      return equal(html, 'bar');
    });
    test('should create a collection of DOM elements', function() {
      var element, template;
      template = new Template('test');
      element = template.toElement({
        foo: 'bar'
      });
      return equal(element.html(), 'bar');
    });
    return test('should return the HTML string when called w/o new', function() {
      var html;
      html = Template('test', {
        foo: 'bar'
      });
      return equal(html, 'bar');
    });
  });
}).call(this);
