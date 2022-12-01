import indicate, { clearIndicators } from "../indicate"

let fakeEditor, fakeIframe, fakeElem, mockRAF

beforeEach(() => {
  Element.prototype.getBoundingClientRect = jest.fn(() => {
    return {
      width: 120,
      height: 120,
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
    }
  })

  fakeElem = document.createElement("div")
  fakeIframe = document.createElement("iframe")
  fakeEditor = {
    getContainer: () => ({
      querySelector: () => fakeIframe,
    }),
  }

  mockRAF = jest.spyOn(window, "requestAnimationFrame")
})

afterEach(() => {
  document.fullscreenElement = null
  window.requestAnimationFrame.mockRestore()
})

describe("indicate", () => {
  it("removes any existing indicators when run", () => {
    mockRAF
      .mockImplementationOnce((cb) => cb(15)) // This only allows it to happen twice, preventing an infinite loop
      .mockImplementationOnce((cb) => cb(30))

    const el = document.createElement("div")
    el.className = "a11y-checker-selection-indicator"
    el.id = "this_should_be_gone"
    indicate(fakeEditor, fakeElem)
    expect(document.getElementById("this_should_be_gone")).toBeFalsy()
  })

  it("stops adjusting when the indicator is gone", () => {
    mockRAF
      .mockImplementationOnce((cb) => cb(15)) 
      .mockImplementationOnce((cb) => {
        document.querySelector('.a11y-checker-selection-indicator').remove()
        cb(30)
      })
      .mockImplementationOnce((cb) => cb(45))

    indicate(fakeEditor, fakeElem)
    expect(mockRAF).toHaveBeenCalledTimes(2)
  })

  it("puts the indicator in the fullscreeenElement if it exists", () => {
    mockRAF
      .mockImplementationOnce((cb) => cb(15))
      .mockImplementationOnce((cb) => cb(30))

    const d = document.createElement('div')
    d.id = "fullscreen_element"
    document.body.appendChild(d)
    document.fullscreenElement = d
    indicate(fakeEditor, fakeElem)
    expect(d.querySelector('.a11y-checker-selection-indicator')).toBeTruthy()
    
  })
})

describe("clearIndicators", () => {
  it("removes any existing indicators when called", () => {
    const el = document.createElement("div")
    el.className = "a11y-checker-selection-indicator"
    el.id = "this_should_be_gone"
    document.body.appendChild(el)
    clearIndicators()
    expect(document.getElementById("this_should_be_gone")).toBeFalsy()
  })

  it("removes indicators from the passed in parent", () => {
    const d1 = document.createElement("div")
    d1.className = "a11y-checker-selection-indicator"
    d1.id = "this_should_be_here"
    document.body.appendChild(d1)

    const parent = document.createElement("div")
    const el = document.createElement("div")
    el.className = "a11y-checker-selection-indicator"
    el.id = "this_should_be_gone"
    parent.appendChild(el)
    document.body.appendChild(parent)
    clearIndicators(parent)
    expect(document.getElementById("this_should_be_gone")).toBeFalsy()
    expect(document.getElementById("this_should_be_here")).toBeTruthy()
  })

  it("removes indicators from the fullscreenElement", () => {
    const d1 = document.createElement("div")
    d1.className = "a11y-checker-selection-indicator"
    d1.id = "this_should_be_here"
    document.body.appendChild(d1)

    const parent = document.createElement("div")
    const el = document.createElement("div")
    el.className = "a11y-checker-selection-indicator"
    el.id = "this_should_be_gone"
    parent.appendChild(el)
    document.body.appendChild(parent)
    document.fullscreenElement = parent
    clearIndicators()
    expect(document.getElementById("this_should_be_gone")).toBeFalsy()
    expect(document.getElementById("this_should_be_here")).toBeTruthy()
  })
})
