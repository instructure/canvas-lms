import rule from "../img-alt-length"

let el

beforeEach(() => {
  el = document.createElement("img")
})

describe("test", () => {
  test("returns true if alt text is shorter than max length", () => {
    el.setAttribute("alt", "some text")
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns true if not image tag", () => {
    const div = document.createElement("div")
    expect(rule.test(div)).toBeTruthy()
  })

  test("returns true if element has no alt attribute", () => {
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns false if alt is longer than max length", () => {
    const moreThanMaxString = Array(rule["max-alt-length"] + 2).join("x")
    el.setAttribute("alt", moreThanMaxString)
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

describe("form", () => {
  test("returns the proper object", () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("set alt text to value", () => {
    const text = "some text"
    expect(rule.update(el, { alt: text }).getAttribute("alt")).toBe(text)
  })
})

describe("message", () => {
  test("returns the proper message", () => {
    expect(rule.message()).toMatchSnapshot()
  })
})

describe("why", () => {
  test("returns the proper why message", () => {
    expect(rule.why()).toMatchSnapshot()
  })
})
