import rule from "../adjacent-links"

let body, a1, a2

beforeEach(() => {
  body = document.createElement("body")
  a1 = document.createElement("a")
  a2 = document.createElement("a")
  body.appendChild(a1)
  body.appendChild(a2)
})

describe("test", () => {
  test("returns true if not A element", () => {
    expect(rule.test(document.createElement("div"))).toBeTruthy()
  })

  test("returns true if no next child element", () => {
    expect(rule.test(a2)).toBeTruthy()
  })

  test("returns true if next A element does not have same href", () => {
    a1.setAttribute("href", "someval")
    expect(rule.test(a1)).toBeTruthy()
  })

  test("returns false if next A element has same null href", () => {
    expect(rule.test(a1)).toBeFalsy()
  })

  test("returns true if next A element has same text href", () => {
    a1.setAttribute("href", "someval")
    a2.setAttribute("href", "someval")
    expect(rule.test(a1)).toBeFalsy()
  })
})

describe("data", () => {})

describe("form", () => {})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(a1, {})).toBe(a1)
  })

  test("returns A element with combined html content if 'combine' set", () => {
    const content = "this is my text"
    const text1 = document.createTextNode(content)
    a1.appendChild(text1)
    const text2 = document.createTextNode(content)
    a2.appendChild(text2)
    const newA = rule.update(a1, { combine: true })
    expect(newA.textContent).toBe(content + content)
    expect(newA.tagName).toBe("A")
  })

  // https://www.w3.org/TR/WCAG20-TECHS/H2.html
  describe("adjacent image and text links for the same resource", () => {
    const content = "home"
    let img, text
    beforeEach(() => {
      img = document.createElement("img")
      img.setAttribute("alt", content)
      text = document.createTextNode(content)
    })

    test("removes redundant image alt text", () => {
      a1.appendChild(img)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe("")
    })

    test("leaves unique alt text alone", () => {
      const altText = "unique alt text"
      img.setAttribute("alt", altText)
      a1.appendChild(img)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe(altText)
    })

    test("finds solitary images with nesting between them and link", () => {
      const div = document.createElement("div")
      div.appendChild(img)
      a1.appendChild(div)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.tagName).toBe("DIV")
      expect(newA.firstElementChild.firstElementChild.tagName).toBe("IMG")
      expect(newA.firstElementChild.firstElementChild.getAttribute("alt")).toBe(
        ""
      )
    })

    test("ignores non-solitary images", () => {
      const otherText = document.createTextNode("other text")
      a1.appendChild(img)
      a1.appendChild(otherText)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe(content)
    })

    test("doesn't treat surrounding whitespace as non-solitary", () => {
      const otherText = document.createTextNode(" ")
      a1.appendChild(img)
      a1.appendChild(otherText)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe("")
    })

    test("checks redundancy against all text content from the non-image link", () => {
      const part1 = "many"
      const part2 = "words"
      img.setAttribute("alt", part1 + " " + part2)
      a1.appendChild(img)

      const span1 = document.createElement("span")
      const span2 = document.createElement("span")
      span1.appendChild(document.createTextNode(part1))
      span2.appendChild(document.createTextNode(part2))
      a2.appendChild(span1)
      a2.appendChild(document.createTextNode(" "))
      a2.appendChild(span2)

      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe("")
    })

    test("checks redundancy with whitespace normalization", () => {
      const variant1 = " some  whitespace"
      const variant2 = "some whitespace  "
      img.setAttribute("alt", variant1)
      a1.appendChild(img)
      a2.appendChild(document.createTextNode(variant2))

      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe("")
    })

    test("sets data-decorative when removing redundant image alt text", () => {
      a1.appendChild(img)
      a2.appendChild(text)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("data-decorative")).toBe(
        "true"
      )
    })

    test("works with image on right as well", () => {
      a1.appendChild(text)
      a2.appendChild(img)
      const newA = rule.update(a1, { combine: true })
      expect(newA.firstElementChild.getAttribute("alt")).toBe("")
    })
  })
})
