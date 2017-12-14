import React from "react"
import Checker from "../checker"
import { shallow } from "enzyme"
import util from "util"

const promisify = util.promisify

jest.mock("../../rules/index")

let component, instance, node, child, child2, body

beforeAll(() => {
  // jsdom doesn't support selection apis
  const mockSelection = {
    removeAllRanges: jest.fn(),
    addRange: jest.fn()
  }
  document.getSelection = jest.fn().mockReturnValue(mockSelection)
  const mockRange = {
    selectNodeContents: jest.fn(),
    selectNode: jest.fn()
  }
  document.createRange = jest.fn().mockReturnValue(mockRange)
  Element.prototype.scrollIntoView = jest.fn()
})

beforeEach(() => {
  body = document.createElement("body")
  node = document.createElement("div")
  body.appendChild(node)
  child = node.appendChild(document.createElement("div"))
  child2 = node.appendChild(document.createElement("div"))
  component = shallow(<Checker getBody={() => node} />)
  instance = component.instance()
})

describe("setConfig", () => {
  test("sets config state", () => {
    const conf = { disableContrastCheck: true }
    instance.setConfig(conf)
    expect(instance.state.config).toEqual(conf)
  })
})

describe("check", () => {
  test("doesn't check nodes with data-ignore-a11y-check", async () => {
    child.setAttribute("data-ignore-a11y-check", "")
    node.removeChild(child2)
    await promisify(instance.check.bind(instance))()
    expect(instance.state.errors.length).toBe(0)
  })

  test("checks nodes without data-ignore-a11y-check", async () => {
    await promisify(instance.check.bind(instance))()
    expect(instance.state.errors.length).toBe(2)
  })

  test("passes config to rule test functions", async () => {
    const conf = { disableContrastCheck: true }
    instance.setConfig(conf)
    await promisify(instance.check.bind(instance))()
    const error = instance.state.errors[0]
    expect(error.rule.test).toHaveBeenCalledWith(error.node, conf)
  })

  test("calls beforeCheck when provided it as a config option", async () => {
    const testCallback = jest.fn()
    const beforeCheck = (ed, done) => {
      testCallback()
      done()
    }
    const conf = { beforeCheck }
    instance.setConfig(conf)
    await promisify(instance.check.bind(instance))()
    expect(testCallback).toHaveBeenCalled()
  })

  test("calls afterCheck when provided it as a config option", async () => {
    const testCallback = jest.fn()
    const afterCheck = (ed, done) => {
      testCallback()
      done()
    }
    const conf = { afterCheck }
    instance.setConfig(conf)
    await promisify(instance.check.bind(instance))()
    expect(testCallback).toHaveBeenCalled()
  })

  test("calls both beforeCheck and afterCheck when both are provided", async () => {
    const beforeCallback = jest.fn()
    const afterCallback = jest.fn()

    const beforeCheck = (ed, done) => {
      beforeCallback()
      done()
    }
    const afterCheck = (ed, done) => {
      afterCallback()
      done()
    }

    const conf = { afterCheck, beforeCheck }
    instance.setConfig(conf)
    await promisify(instance.check.bind(instance))()
    expect(beforeCallback).toHaveBeenCalled()
    expect(afterCallback).toHaveBeenCalled()
  })

  test("calls beforeCheck and afterCheck providing a done callback and an editor instance", async () => {
    component = shallow(
      <Checker getBody={() => node} editor={{ someObject: true }} />
    )
    instance = component.instance()
    const beforeCallback = jest.fn()
    const afterCallback = jest.fn()

    const beforeCheck = (ed, done) => {
      expect(ed).toEqual({ someObject: true })
      beforeCallback()
      done()
    }
    const afterCheck = (ed, done) => {
      expect(ed).toEqual({ someObject: true })
      afterCallback()
      done()
    }

    const conf = { afterCheck, beforeCheck }
    instance.setConfig(conf)
    await promisify(instance.check.bind(instance))()
  })
})

describe("setErrorIndex", () => {
  beforeEach(async () => {
    await promisify(instance.check.bind(instance))()
    component.update()
  })

  test("runs clean up", () => {
    jest.spyOn(instance, "onLeaveError")
    instance.setErrorIndex(0)
    expect(instance.onLeaveError).toHaveBeenCalled()
  })

  test("sets error index if in range", () => {
    instance.setErrorIndex(1)
    expect(instance.state.errorIndex).toBe(1)
  })

  test("sets index to zero if out of range", () => {
    instance.setErrorIndex(2)
    expect(instance.state.errorIndex).toBe(0)
  })
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
  let ev, error

  beforeEach(async () => {
    await promisify(instance.check.bind(instance))()
    component.update()
    error = instance.state.errors[0]
    ev = { preventDefault: jest.fn() }
    jest.spyOn(instance, "check")
  })

  test("updates the real node", () => {
    instance.fixIssue(ev)
    const formState = instance.state.formState
    expect(error.rule.update).toHaveBeenCalledWith(error.node, formState)
  })

  test("checks everything after applying a fix", () => {
    instance.fixIssue(ev)
    expect(instance.check).toHaveBeenCalled()
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
