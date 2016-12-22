define(['compiled/gradebook2/Gradebook',
  "underscore",
  "helpers/fakeENV",
], (Gradebook, _, fakeENV) => {
  module("addRow", {
    setup: function() {
      fakeENV.setup({
        GRADEBOOK_OPTIONS: { context_id: 1 },
      });
    },
    teardown: () => fakeENV.teardown(),
  });

  test("doesn't add filtered out users", () => {
    const gb = {
      sections_enabled: true,
      sections: {"1": {name: "Section 1"}, "2": {name: "Section 2"}},
      options: {},
      rows: [],
      sectionToShow: "2", // this is the filter
      ...Gradebook.prototype
    };

    const student1 = {
      enrollments: [{grades: {}}],
      sections: ["1"],
      name: "student",
    };
    const student2 = {...student1, sections: ["2"]};
    const student3 = {...student1, sections: ["2"]};
    [student1, student2, student3].forEach(s => gb.addRow(s));

    ok(student1.row == null, "filtered out students get no row number");
    ok(student2.row === 0, "other students do get a row number");
    ok(student3.row === 1, "row number increments");
    ok(_.isEqual(gb.rows, [student2, student3]));
  });
});

