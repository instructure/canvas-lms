describe("Indicator", () => {
  beforeEach(() => {
    cy.visit("http://127.0.0.1:8080")
    cy.get("#editor1 [aria-label='Check Accessibility']").click()
  })

  it("should indicate errors when they are active in the checker", () => {
    cy.get(".a11y-checker-selection-indicator").should("be.visible")
  })

  it("should not show the indicator when scrolling down out of the iframe", () => {
    cy.get(".a11y-checker-selection-indicator").should("be.visible")
    cy.get("#editor1 iframe").then($iframe => {
      const $body = $iframe.contents().find("body")
      $body
        .find("p")
        .last()[0]
        .scrollIntoView()
      cy.get(".a11y-checker-selection-indicator").should("be.hidden")
    })
  })

  it("should not show the indicator when scrolled up out of the iframe", () => {
    cy.get("[aria-label='Accessibility Checker']").within(() => {
      // Because of some async stuff the last issue isn't actually at the bottom
      // of the page like we want here
      cy.contains("Prev").click()
      cy.contains("Prev").click()
    })
    cy.get(".a11y-checker-selection-indicator").should("be.visible")
    cy.get("#editor1 iframe").then($iframe => {
      const $body = $iframe.contents().find("body")
      $body
        .find("p")
        .first()[0]
        .scrollIntoView()
      cy.get(".a11y-checker-selection-indicator").should("be.hidden")
    })
  })

  it("should remove the indicator when the a11y checker is closed", () => {
    cy.get(".a11y-checker-selection-indicator").should("be.visible")
    cy.get("[aria-label='Accessibility Checker']").within(() => {
      cy.contains("Close Accessibility Checker").click()
    })
    cy.get(".a11y-checker-selection-indicator").should("not.exist")
  })
})

describe("Indicator Error Interactions", () => {
  beforeEach(() => {
    cy.visit("http://127.0.0.1:8080")
    cy.get("#editor2 [aria-label='Check Accessibility']").click()
  })

  it("should remove the indicator after clearing the last error", () => {
    cy.get("[aria-label='Accessibility Checker']").within(() => {
      cy.get('[type="checkbox"]').check({ force: true }) // force it because it's under a span
      cy.contains("Apply").click()
    })
    cy.get(".a11y-checker-selection-indicator").should("not.exist")
  })
})
