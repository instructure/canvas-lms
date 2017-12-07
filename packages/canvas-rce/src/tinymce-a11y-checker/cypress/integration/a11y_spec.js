describe("a11y Checker", () => {
  it("should open up the a11y checker", () => {
    cy.visit("http://127.0.0.1:8080")
    cy.get("[aria-label='Check Accessibility']").click()
    let checker = cy.get("[aria-label='Accessibility Checker']")
    expect(checker).to.exist
  })
})
