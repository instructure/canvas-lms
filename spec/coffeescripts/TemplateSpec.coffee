define [
  'js!vendor/jquery-1.6.4.js!order'
  'js!vendor/handlebars.vm.js!order'
  'js!compiled/Template.js!order'
  'js!specs/helpers/TemplateHelper.js!order'
], ->

  module 'Template'
  test 'should create an HTML string from a template', ->
    # templates names derived from path in app/views/jst/
    # here the file app/views/jst/test.handlebars becomes 'test'
    template = new Template 'test'
    html = template.toHTML(foo: 'bar')
    equal html, 'bar'

  test 'should create a collection of DOM elements', ->
    template = new Template 'test'
    element = template.toElement(foo: 'bar')
    equal element.html(), 'bar'

  test 'should return the HTML string when called w/o new', ->
    html = Template('test', {foo: 'bar'})
    equal html, 'bar'

