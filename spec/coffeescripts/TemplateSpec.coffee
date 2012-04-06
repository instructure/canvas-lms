define [
  'helpers/testTemplate'
  'compiled/Template'
], (_,Template) ->

  module 'Template'
  test 'should create an HTML string from a template', ->
    # templates names derived from path in app/views/jst/
    # here the file app/views/jst/test.handlebars becomes 'test'
    template = new Template 'test_template'
    html = template.toHTML(foo: 'bar')
    equal html, 'bar'

  test 'should create a collection of DOM elements', ->
    template = new Template 'test_template'
    element = template.toElement(foo: 'bar')
    equal element.html(), 'bar'

  test 'should return the HTML string when called w/o new', ->
    html = Template('test_template', {foo: 'bar'})
    equal html, 'bar'
