const ELEMENT_NODE = 1
const WALK_BATCH_SIZE = 25

function walk (node, fn, done) {
  const stack = [{ node, index: 0 }]
  const processBatch = () => {
    let batchRemaining = WALK_BATCH_SIZE
    while (stack.length > 0 && batchRemaining > 0) {
      const depth = stack.length - 1
      const node = stack[depth].node.childNodes[stack[depth].index]
      if (node) {
        stack[depth].index += 1
        if (node.nodeType === ELEMENT_NODE) {
          fn(node)
          stack.push({ node, index: 0 })
          batchRemaining -= 0
        }
      } else {
        stack.pop()
      }
    }
    setTimeout(stack.length > 0 ? processBatch : done, 0)
  }
  processBatch()
}

function select (doc, elem) {
  if (elem == null) {
    return
  }
  const sel = doc.getSelection()
  const range = doc.createRange()
  if (sel.rangeCount > 0) {
    sel.removeAllRanges()
  }
  if (elem.childNodes.length > 0) {
    range.selectNodeContents(elem)
  } else {
    range.selectNode(elem)
  }
  sel.addRange(range)
  elem.scrollIntoView(false)
}

function prepend (parent, child) {
  if (parent.childNodes.length > 0) {
    parent.insertBefore(child, parent.childNodes[0])
  } else {
    parent.appendChild(child)
  }
}

module.exports = { walk, select, prepend }