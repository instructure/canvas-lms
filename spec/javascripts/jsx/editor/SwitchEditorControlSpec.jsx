define([
  'react',
  'react-addons-test-utils',
  'jsx/editor/SwitchEditorControl',
  'jsx/shared/rce/RichContentEditor'
], (React, TestUtils, SwitchEditorControl, RichContentEditor) => {

  QUnit.module("SwitchEditorControl", {
    setup() {
      sinon.stub(RichContentEditor, 'callOnRCE')
    },

    teardown() {
      RichContentEditor.callOnRCE.restore()
    }
  });

  test('changes text on each click', ()=>{
    let textarea = {}
    let element = React.createElement(SwitchEditorControl, {textarea: textarea})
    let component = TestUtils.renderIntoDocument(element)
    let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
    equal(link.props.className, "switch-views__link__html")
    TestUtils.Simulate.click(link.getDOMNode())
    equal(link.props.className, "switch-views__link__rce")
  })

  test("passes textarea through to editor for toggling", ()=>{
    let textarea = {id: "the text area"}
    let element = React.createElement(SwitchEditorControl, {textarea: textarea})
    let component = TestUtils.renderIntoDocument(element)
    let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok(RichContentEditor.callOnRCE.calledWith(textarea))
  })


});
