import rules from "../index"

const ruleMap = rules.map(rule => [rule.id, rule])

test.each(ruleMap)(
  "%s should have a linkText function if it has a link",
  (ruleId, rule) => {
    if (rule.link && rule.link.length) {
      expect(rule.linkText).toBeInstanceOf(Function)
    }
  }
)

test("all rules should have an id property", () => {
  expect(ruleMap.every(x => x[0])).toBeTruthy()
})

test("all rules should have unique id properties", () => {
  const ruleSet = new Set()
  ruleMap.forEach(x => ruleSet.add(x[0]))
  expect(ruleSet.size).toBe(ruleMap.length)
})
