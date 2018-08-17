import indicate from "../indicate"

let fakeEditor, fakeIframe, fakeElem

beforeEach(() => {
  Element.prototype.getBoundingClientRect = jest.fn(() => {
    return {
      width: 120,
      height: 120,
      top: 0,
      left: 0,
      bottom: 0,
      right: 0
    }
  })

  fakeElem = document.createElement("div")
  fakeIframe = document.createElement("iframe")
  fakeEditor = {
    getContainer: () => ({
      querySelector: () => fakeIframe
    })
  }

  jest
    .spyOn(window, "requestAnimationFrame")
    .mockImplementationOnce(cb => cb()) // This only allows it to happen twice, preventing an infinite loop
    .mockImplementationOnce(cb => cb())
})

afterEach(() => {
  window.requestAnimationFrame.mockRestore()
})

it("removes any existing indicators when run", () => {
  const el = document.createElement("div")
  el.className = "a11y-checker-selection-indicator"
  el.id = "this_should_be_gone"
  indicate(fakeEditor, fakeElem)
  expect(document.getElementById("this_should_be_gone")).toBeFalsy()
})
