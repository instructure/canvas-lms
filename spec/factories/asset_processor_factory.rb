# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
module Factories
  def lti_asset_processor_model(overrides = {})
    assingment_opts = overrides.delete(:assignment_opts) || {}
    external_tool_context = overrides.delete(:external_tool_context)
    props = {
      title: "title",
      text: "text",
      custom: { customkey: "customvar", raid: "$Canvas.root_account.id" },
      icon: { url: "https://example.com/icon.png", width: 32, height: 32 },
      window: { targetName: "mytoolwin", width: 500, height: 400, windowFeatures: "left=100,top=100" },
      iframe: { width: 500, height: 400 },
      report: { released: false,
                indicator: true,
                url: "https://example.com/my_special_target_uri",
                custom: {
                  customkey: "report_overrided",
                  raid2: "$Canvas.root_account.id",
                } },
    }.with_indifferent_access.merge(overrides)
    props[:context_external_tool] ||=
      props.delete(:tool) || external_tool_1_3_model(context: external_tool_context, placements: ["ActivityAssetProcessor"])
    props[:assignment] ||= assignment_model(assingment_opts)
    props[:url] ||= props[:context_external_tool].url
    Lti::AssetProcessor.create!(**props)
  end

  def lti_asset_report_model(overrides = {})
    props = {
      report_type: "originality",
      timestamp: Time.zone.now,
      title: "Turnitin Originality",
      priority: 0,
      processing_progress: "NotReady",
      extensions: { "https://example.com/foo" => "bar" },
    }.with_indifferent_access.merge(overrides).compact

    props[:asset_processor] ||=
      props.delete(:lti_asset_processor_id)&.then { Lti::AssetProcessor.find(it) } ||
      lti_asset_processor_model
    props[:asset] ||=
      props.delete(:lti_asset_id)&.then { Lti::Asset.find(it) } ||
      lti_asset_model(
        submission: props.delete(:submission) || submission_model(
          user: props[:user],
          assignment: props[:asset_processor].assignment
        ),
        attachment: props.delete(:attachment)
      )

    Lti::AssetReport.create!(**props)
  end

  def processed_lti_asset_report_model(overrides = {})
    new_overrides = {
      comment: "Uh-oh",
      result: "83/100",
      indication_color: "#EC0000",
      indication_alt: "High percentage of matched text.",
      priority: 5,
      processing_progress: "Processed",
    }.with_indifferent_access.merge(overrides)
    lti_asset_report_model(new_overrides)
  end

  def failed_lti_asset_report_model(overrides = {})
    new_overrides = {
      comment: "Oops, I don't know how to process that!",
      processing_progress: "Failed",
      error_code: "UNSUPPORTED_ASSET_TYPE"
    }.with_indifferent_access.merge(overrides)
    lti_asset_report_model(new_overrides)
  end

  def lti_asset_model(overrides = {})
    props = overrides.dup
    props[:submission] ||= submission_model
    if props[:submission].submission_type == "online_text_entry"
      props[:submission_attempt] ||= props[:submission].attempt
    elsif props[:submission_attempt].blank?
      props[:attachment] ||= attachment_model
    end
    Lti::Asset.create!(**props)
  end

  def lti_asset_processor_eula_model(overrides = {})
    props = overrides.dup
    props[:context_external_tool] ||= external_tool_1_3_model
    props[:user] ||= user_model
    props[:timestamp] ||= Time.zone.now
    props[:accepted] = true if props[:accepted].nil?
    Lti::AssetProcessorEulaAcceptance.create!(**props)
  end
end
