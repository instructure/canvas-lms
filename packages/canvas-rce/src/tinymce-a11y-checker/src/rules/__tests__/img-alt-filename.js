import moxios from "moxios"
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

  test("returns true if alt text is not filename", () => {
    el.setAttribute("alt", "some text")
    return rule.test(el).then(result => expect(result).toBeTruthy())
  })

  test("returns false if alt text is filename", () => {
    el.setAttribute("alt", "file.txt")
    return rule.test(el).then(result => expect(result).toBeFalsy())
  })

  describe("with redirects", () => {
    beforeEach(() => {
      moxios.install()
    })

    afterEach(() => {
      moxios.uninstall()
    })

    test("returns true if alt text is not the filename after resolution of redirects with location header", done => {
      el.setAttribute("alt", "some_img.jpg")
      el.setAttribute("src", "/some_link_that_redirects")
      const ruleResult = rule.test(el)
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 302,
            headers: {
              Location: "/not_some_img.jpg"
            }
          })
          .then(() => {
            ruleResult.then(response => {
              expect(response).toBeTruthy()
              done()
            })
          })
      })
    })

    test("returns false if alt text is the filename after resolution of redirects with location header", done => {
      el.setAttribute("alt", "some_img.jpg")
      el.setAttribute("src", "/some_link_that_redirects")
      const ruleResult = rule.test(el)
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 302,
            headers: {
              Location: "/some_img.jpg"
            }
          })
          .then(() => {
            ruleResult.then(response => {
              expect(response).toBeFalsy()
              done()
            })
          })
      })
    })

    test("returns true if alt text is not the filename after resolution of redirects with content-disposition header", done => {
      el.setAttribute("alt", "some_img.jpg")
      el.setAttribute("src", "/some_link_that_redirects")
      const ruleResult = rule.test(el)
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 302,
            headers: {
              Location: "/not_some_img",
              "Content-Disposition": 'attachment; filename="not_some_img.jpg"'
            }
          })
          .then(() => {
            ruleResult.then(response => {
              expect(response).toBeTruthy()
              done()
            })
          })
      })
    })

    test("returns false if alt text is the filename after resolution of redirects with content-disposition header", done => {
      el.setAttribute("alt", "some_img.jpg")
      el.setAttribute("src", "/some_link_that_redirects")
      const ruleResult = rule.test(el)
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 302,
            headers: {
              Location: "/not_some_img",
              "Content-Disposition": 'attachment; filename="some_img.jpg"'
            }
          })
          .then(() => {
            ruleResult.then(response => {
              expect(response).toBeTruthy()
              done()
            })
          })
      })
    })
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

  test("changes alt text if requested", () => {
    const text = "this is my text"
    el.setAttribute("alt", "thisismy.txt")
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
