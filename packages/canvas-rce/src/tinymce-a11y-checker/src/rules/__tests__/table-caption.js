import rule from "../table-caption"

let el

beforeEach(() => {
  el = document.createElement("table")
})

describe("test", () => {
  test("returns true if the element is not a table", () => {
    const elem = document.createElement("div")
    expect(rule.test(elem)).toBe(true)
  })

  test("returns true if the element has a non-empty caption", () => {
    const caption = document.createElement("caption")
    caption.textContent = "Some Caption"
    el.appendChild(caption)
    expect(rule.test(el)).toBe(true)
  })

  test("returns false if the element has an empty caption", () => {
    const caption = document.createElement("caption")
    el.appendChild(caption)
    expect(rule.test(el)).toBe(false)
  })

  test("returns false if the element has a whitespace only caption", () => {
    const caption = document.createElement("caption")
    caption.textContent = " "
    el.appendChild(caption)
    expect(rule.test(el)).toBe(false)
  })
  test("returns false if the element has no caption", () => {
    expect(rule.test(el)).toBe(false)
  })
})

describe("data", () => {
  test("returns empty caption object", () => {
    expect(rule.data()).toMatchSnapshot()
  })
})

describe("form", () => {
  test("returns the appropriate object", () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("updates the existing  caption if one exists", () => {
    const caption = document.createElement("caption")
    caption.textContent = " "
    el.appendChild(caption)
    rule.update(el, { caption: "A caption" })
    expect(caption.textContent).toBe("A caption")
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
