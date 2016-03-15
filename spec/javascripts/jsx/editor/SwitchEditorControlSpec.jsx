define([ 'react', 'jsx/editor/SwitchEditorControl'], (React, SwitchEditorControl) => {
  var TestUtils = React.addons.TestUtils

  module("SwitchEditorControl");

  test('changes text on each click', ()=>{
    let element = React.createElement(SwitchEditorControl, {
      textarea: {},
      richContentEditor: {callOnRCE: ()=>{}}
    })
    let component = TestUtils.renderIntoDocument(element)
    let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
    equal(link.props.className, "switch-views__link__html")
    TestUtils.Simulate.click(link.getDOMNode())
    equal(link.props.className, "switch-views__link__rce")
  })

  test("passes textarea through to editor for toggling", ()=>{
    let textarea = {id: "the text area"}
    let rceStub = sinon.stub()
    let rce = {callOnRCE: rceStub}
    let element = React.createElement(SwitchEditorControl, {textarea: textarea, richContentEditor: rce})
    let component = TestUtils.renderIntoDocument(element)
    let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok(rceStub.calledWith(textarea))
  })


});
