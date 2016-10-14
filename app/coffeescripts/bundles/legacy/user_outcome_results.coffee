require [
  "jquery",
  "i18n!outcomes.user_outcome_results"
], ($, I18n) ->
  $(document).ready ->
    showAllArtifacts = $("#show_all_artifacts_link")
    showAllArtifacts.click (event) ->
      event.preventDefault()
      $("tr.artifact_details").toggle()
      if showAllArtifacts.text() is I18n.t("Show All Artifacts")
        showAllArtifacts.text I18n.t("Hide All Artifacts")
      else
        showAllArtifacts.text I18n.t("Show All Artifacts")
