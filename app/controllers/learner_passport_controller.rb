# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
#

# TODO: eliminate this controller in favor of the generic ReactContentController
# once the legacy grading_periods sub tab is reworked to not need the .scss
# bundles included below with css_bundle
class LearnerPassportController < ApplicationController
  before_action :require_context
  before_action :require_user

  def index
    js_env[:FEATURES][:learner_passport] = @domain_root_account.feature_enabled?(:learner_passport)

    unless @domain_root_account.feature_enabled?(:learner_passport)
      return render status: :not_found, template: "shared/errors/404_message"
    end

    # hide the breadcrumbs application.html.erb renders
    render html: "<style>.ic-app-nav-toggle-and-crumbs.no-print {display: none;}</style>".html_safe, layout: true
  end

  def achievements
    render json: [
      {
        id: "1",
        isNew: true,
        title: "Product Management Short Course",
        issuer: {
          name: "General Assembly",
          url: "https://generalassemb.ly/education/product-management/new-york-city",
          iconUrl: "data:image/png;base64,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",
        },
        issuedOn: "2023-10-30",
        expiresOn: "2033-10-30",
        type: "Certificate of Completion",
        criteria: "To earn this badge, participants must complete 50 yours of study over 10 weeks, and complete a case study project.",
        skills: ["Product Management"],
        imageUrl: nil,
        verifiedBy: "Open Badges"
      },
      {
        id: "2",
        isNew: false,
        title: "C.S. in Computer Science",
        issuer: {
          name: "The Ohio State University",
          url: "https://www.osu.edu/",
        },
        issuedOn: "2020-05-03",
        expiresOn: nil,
        type: "Bachelor of Science",
        imageUrl: "https://www.osu.edu/images/osu-logo-blocko.svg",
        verifiedBy: "Open Badges"
      },
      {
        id: "3",
        isNew: false,
        title: "National Merit Scholar",
        issuer: {
          name: "NMSC",
          url: "https://www.nationalmerit.org/",
        },
        issuedOn: "2016-10-03",
        expiresOn: nil,
        imageUrl: "https://www.nationalmerit.org/s/1758/images/logo.png",
        verifiedBy: nil
      },
      {
        id: "4",
        isNew: false,
        title: "CPS High School Diploma",
        issuer: {
          name: "Walnut Hills High School",
          url: "http://www.walnuthillseagles.com/",
          iconUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png",
        },
        issuedOn: "2016-05-27",
        expiresOn: nil,
        imageUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png",
        verifiedBy: nil
      }
    ]
  end
end
