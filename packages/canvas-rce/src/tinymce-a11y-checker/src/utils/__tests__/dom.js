const dom = require("../dom")

test("walk calls function with each child element depth first", () => {
  document.body.innerHTML = `
    <div>
      <h1>Test Heading</h1>
      <p>Test <a href="">Link</a></p>
      <h2>Test Subheading</h2>
    </div>
  `
  const nodeNames = []
  const fn = node => nodeNames.push(node.nodeName)
  dom.walk(document.body, fn)
  expect(nodeNames).toEqual(["DIV", "H1", "P", "A", "H2"])
})

test("select creats a range for the doc and selects the node", () => {
  const range = { selectNode: jest.fn() }
  const doc = { createRange: () => range }
  const node = "node"
  dom.select(doc, node)
  expect(range.selectNode).toBeCalledWith(node)
})

test("select does nothing if node is underfined", () => {
  const range = { selectNode: jest.fn() }
  const doc = { createRange: jest.fn().mockReturnValue(range) }
  const node = undefined
  dom.select(doc, node)
  expect(doc.createRange).not.toBeCalled()
  expect(range.selectNode).not.toBeCalled()
})
