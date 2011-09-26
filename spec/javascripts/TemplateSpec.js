(function() {
  describe("Template", function() {
    it('should create an HTML string from a template', function() {
      var html, template;
      template = new Template('test');
      html = template.toHTML({
        foo: 'bar'
      });
      return expect(html).toEqual('bar');
    });
    it('should create a collection of DOM elements', function() {
      var element, template;
      template = new Template('test');
      element = template.toElement({
        foo: 'bar'
      });
      return expect(element.html()).toEqual('bar');
    });
    return it('should return the HTML string when called w/o new', function() {
      var html;
      html = Template('test', {
        foo: 'bar'
      });
      return expect(html).toEqual('bar');
    });
  });
}).call(this);
