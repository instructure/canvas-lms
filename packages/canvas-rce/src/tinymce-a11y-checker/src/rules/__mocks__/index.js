module.exports = [
  {
    test: () => false,
    data: () => ({
      select: "a",
      checkbox: true,
      color: "rgba(40, 100, 200, 0.6)",
      text: "Text"
    }),
    form: () => [
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
      }
    ],
    update: () => {},
    message: () => "Error Message",
    why: () => "Why Text",
    link: "http://some-url"
  }
]
