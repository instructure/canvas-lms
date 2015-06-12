define [
  'authentication_providers'
], (authenticationProviders)->

  fixtureNode = null

  appendFixtureHtml = (html)->
    element = document.createElement("div")
    element.innerHTML = html
    fixtureNode.appendChild(element)

  module "AuthenticationProviders.changedAuthType",
    setup: ->
     fixtureNode = document.getElementById("fixtures")

    teardown: ->
     fixtureNode.innerHTML = ""

  test "it hides new auth forms", ->
    appendFixtureHtml("
      <form id='42_form' class='auth-form-container--new'>
        <span>Here is a different new form</span>
      </form>")
    authenticationProviders.changedAuthType("saml")
    newForm = document.getElementById("42_form")
    equal(newForm.style.display, "none")

  test "it reveals a matching form if present", ->
    appendFixtureHtml("
      <form id='saml_form' style='display:none;'>
        <span>Here is the new form</span>
      </form>")
    authenticationProviders.changedAuthType("saml")
    newForm = document.getElementById("saml_form")
    equal(newForm.style.display, "")

  test "it hides the 'nothing picked' message if present", ->
    appendFixtureHtml("<div id='no_auth'>No auth thingy picked</div>")
    authenticationProviders.changedAuthType("ldap")
    noAuthDiv = document.getElementById("no_auth")
    equal(noAuthDiv.style.display, "none")
