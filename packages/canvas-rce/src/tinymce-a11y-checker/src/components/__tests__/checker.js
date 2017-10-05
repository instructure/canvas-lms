const React = require("react")
const Checker = require("../checker")
const { shallow } = require("enzyme")
const { promisify } = require("util")

jest.mock("../../rules/index")

let component, instance, node, child, body

beforeEach(() => {
  body = document.createElement("body")
  node = document.createElement("div")
  body.appendChild(node)
  child = node.appendChild(document.createElement("div"))
  node.appendChild(document.createElement("div"))
  component = shallow(<Checker getBody={() => node} />)
  instance = component.instance()
})

describe("errorRootNode", () => {
  beforeEach(async () => {
    await promisify(instance.check.bind(instance))()
    component.update()
  })

  test("returns error node if rule rootNode returns null", () => {
    expect(instance.errorRootNode()).toBe(instance.errorNode())
  })

  test("returns error node if rule does not define rootNode", () => {
    instance.error().rule = Object.assign({}, instance.errorRule(), {
      rootNode: undefined
    })
    expect(instance.errorRootNode()).toBe(instance.errorNode())
  })

  test("returns root node if rule rootNode returns non-null value", () => {
    const rootNode = document.createElement("div")
    instance.errorRule().rootNode.mockReturnValueOnce(rootNode)
    expect(instance.errorRootNode()).toBe(rootNode)
  })
})

describe("updateFormState", () => {
  let target

  beforeEach(() => {
    target = { name: "foo", value: "bar" }
  })

  test("sets state to true if target is a checkbox and checked", () => {
    target.type = "checkbox"
    target.checked = true
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(true)
  })

  test("sets state to false if target is a checkbox and not checked", () => {
    target.type = "checkbox"
    target.checked = false
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(false)
  })

  test("sets state to value", () => {
    instance.updateFormState({ target })
    expect(instance.state.formState.foo).toBe(target.value)
  })
})

describe("formStateValid", () => {
  let rule, updatedNode, formState

  beforeEach(async () => {
    formState = { a: 1 }
    updatedNode = document.createElement("p")
    updatedNode.appendChild(document.createTextNode("updated node"))
    body.appendChild(updatedNode)
    await promisify(instance.check.bind(instance))()
    component.update()
    rule = instance.state.errors[0].rule
    rule.update.mockReturnValue(updatedNode)
  })

  test("returns rule test of updated node", () => {
    rule.test.mockReturnValueOnce(true)
    expect(instance.formStateValid(formState)).toBe(true)
    expect(instance.formStateValid(formState)).toBe(false)
    expect(rule.test).toHaveBeenCalledWith(updatedNode)
  })

  test("calls update with a new clone of the error node", () => {
    instance.formStateValid(formState)
    const firstTempNode = instance._tempNode
    let secondTempNode
    rule.update.mockImplementation((elem, data) => {
      secondTempNode = elem
    })
    instance.formStateValid(formState)
    expect(firstTempNode).not.toBe(secondTempNode)
  })

  test("clones root node if defined by rule", () => {
    const parent = document.createElement("div")
    const rootNode = document.createElement("div")
    rootNode.appendChild(instance.state.errors[0].node)
    parent.appendChild(rootNode)
    rule.rootNode.mockReturnValueOnce(rootNode)
    instance.formStateValid(formState)
    expect(instance._tempNode).toEqual(rootNode)
  })
})

describe("fixIssue", () => {
  let updatedNode, ev, error

  beforeEach(async () => {
    updatedNode = "updated node"
    await promisify(instance.check.bind(instance))()
    component.update()
    error = instance.state.errors[0]
    error.rule.update.mockReturnValue(updatedNode)
    ev = { preventDefault: jest.fn() }
  })

  test("replaces error node with elem returned from update", () => {
    instance.fixIssue(ev)
    expect(error.node).toBe(updatedNode)
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
