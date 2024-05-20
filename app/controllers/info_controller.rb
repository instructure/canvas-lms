# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class InfoController < ApplicationController
  skip_before_action :check_pending_otp, only: %i[web_app_manifest]
  skip_before_action :load_account, only: %i[health_check readiness deep]
  skip_before_action :load_user, only: %i[health_check readiness deep browserconfig]

  def styleguide
    render layout: "layouts/styleguide"
  end

  def message_redirect
    m = AssetSignature.find_by_signature(Message, params[:id])
    if m&.url
      redirect_to m.url
    else
      redirect_to "http://#{HostUrl.default_host}/"
    end
  end

  def help_links
    current_user_roles = @current_user.try(:roles, @domain_root_account) || []
    links = @domain_root_account&.help_links

    links = links.select do |link|
      available_to = link[:available_to] || []
      available_to.detect do |role|
        (role == "user" || current_user_roles.include?(role)) ||
          (current_user_roles == ["user"] && role == "unenrolled")
      end
    end

    render json: links
  end

  def health_check
    # This action should perform checks on various subsystems, and raise an exception on failure.
    Account.connection.verify!
    if Delayed::Job == Delayed::Backend::ActiveRecord::Job &&
       Account.connection != Delayed::Job.connection
      Delayed::Job.connection.verify!
    end
    Tempfile.open("heartbeat", ENV["TMPDIR"] || Dir.tmpdir) do |f|
      f.write("heartbeat")
      f.flush
    end
    # consul works; we don't really care about the result, but it should not error trying to
    # get the result
    DynamicSettings.find(tree: :private)["enable_rack_brotli", failsafe: true]
    # vault works; asserting a hash is returned that is not null
    !Canvas::Vault.read("#{Canvas::Vault.kv_mount}/data/secrets").nil? if Canvas::Vault

    # javascript/css build process didn't die, right?
    asset_urls = {
      common_css: css_url_for("common"), # ensures brandable_css_bundles_with_deps exists
      common_js: ActionController::Base.helpers.javascript_path(
        Canvas::Cdn.registry.scripts_for("main").first
      ),
      revved_url: ActionController::Base.helpers.font_path(
        "/fonts/lato/extended/Lato-Regular.woff2"
      )
    }

    respond_to do |format|
      format.html { render plain: "canvas ok" }
      format.json do
        render json:
                               { status: "canvas ok",
                                 asset_urls:,
                                 revision: Canvas.revision,
                                 installation_uuid: Canvas.installation_uuid }
      end
    end
  end

  def health_prognosis
    # do some checks on things that aren't a problem yet, but will be if nothing is done to fix them
    checks = {
      "messages_partition" => Messages::Partitioner.processed?,
      "quizzes_submission_events_partition" => Quizzes::QuizSubmissionEventPartitioner.processed?,
      "versions_partition" => SimplyVersioned::Partitioner.processed?,
    }
    failed = checks.reject { |_k, v| v }.map(&:first)
    if failed.any?
      render json: { status: "failed upcoming health checks - #{failed.join(", ")}" }, status: :internal_server_error
    else
      render json: { status: "canvas will be ok, probably" }
    end
  end

  # for windows live tiles
  def browserconfig
    cancel_cache_buster
    expires_in 10.minutes, public: true
  end

  def test_error
    @context = Course.find(params[:course_id]) if params[:course_id].present?

    if params[:status].present?
      case params[:status].to_i
      when 401
        @unauthorized_reason = :unpublished if params[:reason] == "unpublished"
        @needs_cookies = true if params[:reason] == "needs_cookies"
        return render_unauthorized_action
      when 422
        raise ActionController::InvalidAuthenticityToken, "test_error"
      else
        @not_found_message = "(test_error message details)" if params[:message].present?
        raise RequestError.new("test_error", params[:status].to_i)
      end
    end

    render status: :not_found, template: "shared/errors/404_message"
  end

  def live_events_heartbeat
    Canvas::LiveEvents.heartbeat
    render plain: "heartbeat event sent at #{Time.now.utc.iso8601}"
  end

  def web_app_manifest
    # brand_variable returns a value that we expect to go through a rails
    # asset helper, so we need to do that manually here
    icon = helpers.image_path(brand_variable("ic-brand-apple-touch-icon"))
    render json: {
      name: "Canvas",
      short_name: "Canvas",
      icons: [
        {
          src: icon,
          sizes: "144x144",
          type: "image/png"
        },
        {
          src: icon,
          sizes: "192x192",
          type: "image/png"
        }
      ],
      prefer_related_applications: true,
      related_applications: [
        {
          platform: "play",
          url: "https://play.google.com/store/apps/details?id=com.instructure.candroid",
          id: "com.instructure.candroid"
        },
        {
          platform: "itunes",
          url: "https://itunes.apple.com/app/canvas-by-instructure/id480883488"
        }
      ],
      start_url: "/",
      display: "minimal-ui"
    }
  end

  def readiness
    # This action provides a clear signal for assessing system components that are "owned"
    # by Canvas and are ultimately responsible for being alive and able to serve consumer traffic

    components = HealthChecks.process_readiness_checks(false)

    render_readiness_json(components, false)
  end

  def deep
    # This action provides a clear signal for assessing our critical and secondary dependencies
    # such that we can successfully complete consumer requests

    deep_check =
      Rails.cache.fetch(:deep_health_check, expires_in: 60.seconds) do
        HealthChecks.process_deep_checks
      end

    failed = deep_check[:critical].reject { |_k, v| v[:status] }.map(&:first)
    render_deep_json(deep_check[:critical], deep_check[:secondary], failed.any? ? 503 : 200)
  end

  private

  def render_readiness_json(components, is_deep_check)
    failed = components.reject { |_k, v| v[:status] }.map(&:first)
    status_code = failed.any? ? 503 : 200

    readiness_json = { status: status_code, components: components_to_hash(components) }
    return readiness_json if is_deep_check

    render json: readiness_json, status: status_code
  end

  def render_deep_json(critical, secondary, status_code)
    components = HealthChecks.process_readiness_checks(true)
    readiness_response = render_readiness_json(components, true)

    status = (readiness_response[:status] == 503) ? readiness_response[:status] : status_code

    response = {
      readiness: components,
      critical:,
      secondary:,
    }

    HealthChecks.send_to_statsd(response, { cluster: Shard.current.database_server_id })

    render json: {
             status:,
             readiness: readiness_response,
             critical: components_to_hash(critical),
             secondary: components_to_hash(secondary),
           },
           status:
  end

  def components_to_hash(components)
    components.map do |name, value|
      status = value[:status] ? 200 : 503
      message = value[:message]
      time = value[:time]
      { name:, status:, message:, response_time_ms: time }
    end
  end
end
