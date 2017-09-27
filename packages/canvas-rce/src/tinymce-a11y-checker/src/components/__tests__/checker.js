const React = require("react")
const Checker = require("../checker")
const { shallow } = require("enzyme")
const { promisify } = require("util")

jest.mock("../../rules/index")

let component, instance, node

beforeEach(() => {
  node = document.createElement("div")
  node.appendChild(document.createElement("div"))
  node.appendChild(document.createElement("div"))
  component = shallow(<Checker getBody={() => node} />)
  instance = component.instance()
})

describe("updateFormState", () => {
  let target

  beforeEach(() => {
    target = { name: "foo", value: "bar" }
  })

  it("sets state to true if target is a checkbox and checked", () => {
    target.type = "checkbox"
    target.checked = true
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(true)
  })

  it("sets state to false if target is a checkbox and not checked", () => {
    target.type = "checkbox"
    target.checked = false
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(false)
  })

  it("sets state to value", () => {
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(target.value)
  })
})

describe("render", () => {
  test("matches snapshot without errors", () => {
    expect(component).toMatchSnapshot()
  })

  test("matches snapshot with errors", async () => {
    await promisify(instance.check.bind(instance))()
    component.update()
    expect(component).toMatchSnapshot()
  })
})
