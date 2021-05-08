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
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns true if decorative", () => {
    el.setAttribute("data-decorative", "file.txt")
    expect(rule.test(el)).toBeTruthy()
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

  test("returns decorative true if el has data-decorative", () => {
    el.setAttribute("data-decorative", "")
    expect(rule.data(el).decorative).toBeTruthy()
  })

  test("returns decorative false if el does not have data-decorative", () => {
    expect(rule.data(el).decorative).toBeFalsy()
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

  test("sets alt text to empty and role to 'presentation' if decorative", () => {
    rule.update(el, { decorative: true })
    expect(el.getAttribute("alt")).toBe("")
    expect(el.hasAttribute("data-decorative")).toBeTruthy()
    expect(el.getAttribute("role")).toBe("presentation")
  })

  test("sets alt text and removes role if not decorative", () => {
    el.setAttribute("alt", "")
    el.setAttribute("data-decorative", "")
    el.setAttribute("role", "presentation")
    rule.update(el, { decorative: false, alt: "some text" })
    expect(el.getAttribute("alt")).toBe("some text")
    expect(el.hasAttribute("data-decorative")).toBeFalsy()
    expect(el.hasAttribute("role")).toBeFalsy()
  })

  test("changes alt text if not decorative", () => {
    const text = "this is my text"
    el.setAttribute("alt", "thisismy.txt")
    expect(
      rule.update(el, { alt: text, decorative: false }).getAttribute("alt")
    ).toBe(text)
  })

  test("removes data-decorative if not decorative", () => {
    el.setAttribute("data-decorative", "")
    rule.update(el, { decorative: false })
    expect(el.hasAttribute("data-decorative")).toBeFalsy()
  })

  test("sets alt text to empty and data-decorative if decorative", () => {
    rule.update(el, { decorative: true })
    expect(el.hasAttribute("data-decorative")).toBeTruthy()
    expect(el.getAttribute("alt")).toBe("")
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

describe("linkText", () => {
  test("returns the proper why message", () => {
    expect(rule.linkText()).toMatchSnapshot()
  })
})
