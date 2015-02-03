require [
  "jquery",
  "i18n!outcomes.user_outcome_results"
], ($, I18n) ->
  $(document).ready ->
    showAllArtifacts = $("#show_all_artifacts_link")
    showAllArtifacts.click (event) ->
      event.preventDefault()
      $("tr.artifact_details").toggle()
      if showAllArtifacts.text() is I18n.t("#buttons.show_all_artifacts", "Show All Artifacts")
        showAllArtifacts.text I18n("#buttons.hide_all_artifacts", "Hide All Artifacts")
      else
        showAllArtifacts.text I18n.t("#buttons.show_all_artifacts", "Show All Artifacts")
