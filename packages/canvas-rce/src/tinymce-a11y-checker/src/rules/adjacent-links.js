import formatMessage from "../format-message"

const shouldMergeAnchors = (elem1, elem2) => {
  if (!elem1 || !elem2 || elem1.tagName !== "A" || elem2.tagName !== "A") {
    return false
  }
  return elem1.getAttribute("href") === elem2.getAttribute("href")
}

const notWhitespace = node => {
  return node.nodeType !== Node.TEXT_NODE || node.textContent.match(/\S/)
}

const onlyChild = parent => {
  const child = parent.firstElementChild
  if (!child) {
    return null
  }
  if ([...parent.childNodes].filter(notWhitespace).length > 1) {
    return null
  }
  return child
}

const solitaryDescendantImage = link => {
  let parent = link
  let child = onlyChild(parent)
  while (child) {
    if (child.tagName === "IMG") {
      return child
    }
    parent = child
    child = onlyChild(parent)
  }
  return null
}

const normalizeText = text => {
  // normalize whitespace and trim leading and trailing whitespace
  return text.replace(/\s+/g, " ").trim()
}

const descendantImageWithRedundantAltText = (left, right) => {
  let leftImage = solitaryDescendantImage(left)
  let rightImage = solitaryDescendantImage(right)
  if (
    leftImage &&
    !rightImage &&
    normalizeText(leftImage.getAttribute("alt")) ===
      normalizeText(right.textContent)
  ) {
    return leftImage
  } else if (
    rightImage &&
    !leftImage &&
    normalizeText(rightImage.getAttribute("alt")) ===
      normalizeText(left.textContent)
  ) {
    return rightImage
  } else {
    return null
  }
}

export default {
  test: function(elem) {
    if (elem.tagName != "A") {
      return true
    }
    return !shouldMergeAnchors(elem, elem.nextElementSibling)
  },

  data: elem => {
    return {
      combine: false
    }
  },

  form: () => [
    {
      label: formatMessage("Merge links"),
      checkbox: true,
      dataKey: "combine"
    }
  ],

  update: function(elem, data) {
    const rootElem = elem.parentNode
    if (data.combine) {
      const next = elem.nextElementSibling

      // https://www.w3.org/TR/WCAG20-TECHS/H2.html
      const image = descendantImageWithRedundantAltText(elem, next)
      if (image) {
        image.setAttribute("data-decorative", "true")
        image.setAttribute("alt", "")
      }

      rootElem.removeChild(next)
      elem.innerHTML += next.innerHTML
    }
    return elem
  },

  rootNode: function(elem) {
    return elem.parentNode
  },

  message: () =>
    formatMessage("Adjacent links with the same URL should be a single link."),

  why: () =>
    formatMessage(
      "Keyboards navigate to links using the Tab key. Two adjacent links that direct to the same destination can be confusing to keyboard users."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H2.html"
}
