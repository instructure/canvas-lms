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

describe("select", () => {
  let node, doc, range, sel

  beforeEach(() => {
    range = { selectNode: jest.fn() }
    sel = { addRange: jest.fn(), removeAllRanges: jest.fn() }
    doc = { createRange: () => range, getSelection: () => sel }
    node = { scrollIntoView: jest.fn(), ownerDocument: doc, childNodes: [] }
  })

  test("select creates a range for the doc and selects the node", () => {
    dom.select(node)
    expect(range.selectNode).toBeCalledWith(node)
  })

  test("select does not throw if node is underfined or null", () => {
    dom.select(undefined)
    dom.select(null)
  })
})
