const strings = require("../strings")

describe("firstWords", () => {
  test("returns first words with an elipsis if longer", () => {
    expect(strings.firstWords(" this is a \ntest   ", 3)).toBe("this is a…")
  })

  test("returns first words without an elipsis if same", () => {
    expect(strings.firstWords(" this is a \ntest   ", 4)).toBe("this is a test")
  })

  test("returns all words without elipsis if fewer", () => {
    expect(strings.firstWords("this\nis", 5)).toBe("this is")
  })
})

describe("filename", () => {
  test("returns the filename for a full url with querystring", () => {
    expect(
      strings.filename("https://foo.com/this/is/a/test.png?a=123&b=c")
    ).toBe("test.png")
  })

  test("returns the filename for a full url without querystring", () => {
    expect(strings.filename("https://foo.com/this/is/a/test.png")).toBe(
      "test.png"
    )
  })

  test("returns the filename for relative paths", () => {
    expect(strings.filename("../this/is/a/test.png")).toBe("test.png")
  })

  test("returns the filename if no path", () => {
    expect(strings.filename("test.png")).toBe("test.png")
  })
})
