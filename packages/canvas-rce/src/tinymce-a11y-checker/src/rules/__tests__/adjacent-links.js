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
})
