export default [
  {
    test: jest.fn().mockReturnValue(false),
    data: jest.fn().mockReturnValue({
      select: "a",
      checkbox: true,
      color: "rgba(40, 100, 200, 0.6)",
      text: "Text"
    }),
    form: jest.fn().mockReturnValue([
      {
        label: "Select Field",
        dataKey: "select",
        options: [["a", "A"], ["b", "B"]]
      },
      {
        label: "Select Field",
        dataKey: "checkbox",
        checkbox: true
      },
      {
        label: "Select Field",
        dataKey: "color",
        color: true
      },
      {
        label: "Text Field",
        dataKey: "text",
        disabledIf: () => true
      },
      {
        label: "Text Area",
        dataKey: "textarea",
        textarea: true
      }
    ]),
    rootNode: jest.fn(),
    update: jest.fn(),
    message: jest.fn().mockReturnValue("Error Message"),
    why: jest.fn().mockReturnValue("Why Text"),
    link: "http://some-url",
    linkText: jest.fn().mockReturnValue("Link for learning more")
  }
]
