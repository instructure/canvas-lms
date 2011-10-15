describe "Template", ->

  it 'should create an HTML string from a template', ->
    # templates names derived from path in app/views/jst/
    # here the file app/views/jst/test.handlebars becomes 'test'
    template = new Template 'test'
    html = template.toHTML(foo: 'bar')
    expect(html).toEqual('bar')

  it 'should create a collection of DOM elements', ->
    template = new Template 'test'
    element = template.toElement(foo: 'bar')
    expect(element.html()).toEqual('bar')

  it 'should return the HTML string when called w/o new', ->
    html = Template('test', {foo: 'bar'})
    expect(html).toEqual('bar')