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

function select (elem) {
  if (elem == null) {
    return
  }
  const doc = elem.ownerDocument
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
  elem.scrollIntoView()
}

function prepend (parent, child) {
  if (parent.childNodes.length > 0) {
    parent.insertBefore(child, parent.childNodes[0])
  } else {
    parent.appendChild(child)
  }
}

function changeTag (elem, tagName) {
  const newElem = elem.ownerDocument.createElement(tagName)
  while (elem.firstChild) {
    newElem.appendChild(elem.firstChild)
  }
  for (let i = elem.attributes.length - 1; i >= 0; --i) {
    newElem.attributes.setNamedItem(elem.attributes[i].cloneNode())
  }
  elem.parentNode.replaceChild(newElem, elem)
  return newElem
}

module.exports = { walk, select, prepend, changeTag }