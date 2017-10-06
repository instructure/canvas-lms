import rule from "../img-alt-filename"

let el

beforeEach(() => {
  el = document.createElement("img")
  el.setAttribute("src", "/file.txt")
})

describe("test", () => {
  test("returns true if alt text is empty", () => {
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns true if not img tag", () => {
    const div = document.createElement("div")
    expect(rule.test(div)).toBeTruthy()
  })

  test("returns true if alt text is not filename", () => {
    el.setAttribute("alt", "some text")
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns false if alt text is filename", () => {
    el.setAttribute("alt", "file.txt")
    expect(rule.test(el)).toBeFalsy()
  })
})

describe("data", () => {
  test("returns alt text", () => {
    el.setAttribute("alt", "some text")
    expect(rule.data(el).alt).toBe("some text")
  })

  test("returns empty alt text if no alt attribute", () => {
    expect(rule.data(el).alt).toBe("")
  })
})

describe("form", () => {})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("changes alt text if requested", () => {
    const text = "this is my text"
    el.setAttribute("alt", "thisismy.txt")
    expect(rule.update(el, { alt: text }).getAttribute("alt")).toBe(text)
  })
})
