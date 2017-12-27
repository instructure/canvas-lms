import React from "react"
import { mount } from "enzyme"
import ColorField from "../color-field"

test("it renders", () => {
  const wrapper = mount(<ColorField label="color" />)
  expect(wrapper.exists()).toBe(true)
})

test("it calls onChange prop with proper values when the picker changes", () => {
  const changeSpy = jest.fn()
  const wrapper = mount(
    <ColorField
      label="color"
      value="rgba(100,100,100,0.7)"
      onChange={changeSpy}
      name="testing"
    />
  )
  // The color picker is wrapped by another color picker, so this lets us get it.
  const colorPicker = wrapper.find("ColorPicker").children("ColorPicker")
  // In an ideal world, we could use Simulate here, but for some reason it wasn't working :(
  // So instead we're calling the onChange handler on the ColorPicker directly
  colorPicker.props().onChange({
    r: 100,
    g: 100,
    b: 100,
    a: 0.7
  })

  expect(changeSpy).toHaveBeenCalledWith({
    target: {
      name: "testing",
      value: "rgba(100, 100, 100, 0.7)"
    }
  })
})

describe("stringifyRGBA", () => {
  it("handles rgba", () => {
    const rgba = {
      r: 100,
      g: 100,
      b: 100,
      a: 0.7
    }

    expect(ColorField.stringifyRGBA(rgba)).toBe("rgba(100, 100, 100, 0.7)")
  })

  it("handles rgb", () => {
    const rgba = {
      r: 100,
      g: 100,
      b: 100,
      a: 1
    }

    expect(ColorField.stringifyRGBA(rgba)).toBe("rgb(100, 100, 100)")
  })
})
