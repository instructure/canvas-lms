describe("a11y Checker", () => {
  it("should open up the a11y checker", () => {
    cy.visit("http://127.0.0.1:8080")
    cy.get("#editor1 [aria-label='Check Accessibility']").click()
    let checker = cy.get("[aria-label='Accessibility Checker']")
    checker.should('exist')
  })

  it("should resolve the last issue then return to the first issue", () => {
    cy.visit("http://127.0.0.1:8080")
    cy.get("#editor1 [aria-label='Check Accessibility']").click()
    cy.get("[aria-label='Accessibility Checker']").within(() => {
      cy.contains("Prev").click()
      cy.get("input[type=text]").type("Kitten")

      cy.contains("Apply").click()
      let issueTitle = cy.contains(/Issue 1\/\d+/)
      issueTitle.should('exist')
    })
  })
})
