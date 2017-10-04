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

describe("pathForNode", () => {
  test("returns empty array of ancestor and decendant are the same", () => {
    const elem = document.createElement("div")
    expect(dom.pathForNode(elem, elem)).toEqual([])
  })

  test("returns null if decendant is not a decendant of ancestor", () => {
    const a = document.createElement("div")
    const b = document.createElement("div")
    expect(dom.pathForNode(a, b)).toBe(null)
  })

  test("returns array with single index if direct child", () => {
    const a = document.createElement("div")
    const b = document.createElement("div")
    a.appendChild(document.createElement("div"))
    a.appendChild(b)
    expect(dom.pathForNode(a, b)).toEqual([1])
  })

  test("returns full index path for nested decendant", () => {
    const a = document.createElement("div")
    const b = document.createElement("div")
    const c = document.createElement("div")
    a.appendChild(document.createElement("div"))
    a.appendChild(b)
    b.appendChild(document.createElement("div"))
    b.appendChild(document.createElement("div"))
    b.appendChild(c)
    expect(dom.pathForNode(a, c)).toEqual([2, 1])
  })
})

describe("nodeByPath", () => {
  test("returns ancestor path is empty array", () => {
    const elem = document.createElement("div")
    expect(dom.nodeByPath(elem, [])).toBe(elem)
  })

  test("returns null if any path index is out of range", () => {
    const elem = document.createElement("div")
    elem.appendChild(document.createElement("div"))
    expect(dom.nodeByPath(elem, [1])).toBe(null)
  })

  test("returns nested decendant by path", () => {
    const a = document.createElement("div")
    const b = document.createElement("div")
    const c = document.createElement("div")
    a.appendChild(document.createElement("div"))
    a.appendChild(b)
    b.appendChild(document.createElement("div"))
    b.appendChild(document.createElement("div"))
    b.appendChild(c)
    expect(dom.nodeByPath(a, [2, 1])).toBe(c)
  })
})
