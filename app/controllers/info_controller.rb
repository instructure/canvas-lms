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
  skip_before_action :load_account, :only => [:health_check, :readiness]
  skip_before_action :load_user, :only => [:health_check, :readiness, :browserconfig]

  def styleguide
    render :layout => "layouts/styleguide"
  end

  def message_redirect
    m = AssetSignature.find_by_signature(Message, params[:id])
    if m && m.url
      redirect_to m.url
    else
      redirect_to "http://#{HostUrl.default_host}/"
    end
  end

  def help_links
    current_user_roles = @current_user.try(:roles, @domain_root_account) || []
    links = @domain_root_account && @domain_root_account.help_links

    links = links.select do |link|
      available_to = link[:available_to] || []
      available_to.detect do |role|
        (role == 'user' || current_user_roles.include?(role)) ||
        (current_user_roles == ['user'] && role == 'unenrolled')
      end
    end

    render :json => links
  end

  def health_check
    # This action should perform checks on various subsystems, and raise an exception on failure.
    Account.connection.active?
    if Delayed::Job == Delayed::Backend::ActiveRecord::Job &&
      Account.connection != Delayed::Job.connection
      Delayed::Job.connection.active?
    end
    Tempfile.open("heartbeat", ENV['TMPDIR'] || Dir.tmpdir) { |f| f.write("heartbeat"); f.flush }
    # consul works; we don't really care about the result, but it should not error trying to
    # get the result
    DynamicSettings.find(tree: :private)['enable_rack_brotli']

    # javascript/css build process didn't die, right?
    asset_urls = {
      common_css: css_url_for("common"), # ensures brandable_css_bundles_with_deps exists
      common_js: ActionController::Base.helpers.javascript_url("#{js_base_url}/common"), # ensures webpack worked
      revved_url: Canvas::Cdn::RevManifest.gulp_manifest.values.first # makes sure `gulp rev` has ran
    }

    respond_to do |format|
      format.html { render plain: 'canvas ok' }
      format.json { render json:
                               { status: 'canvas ok',
                                 asset_urls: asset_urls,
                                 revision: Canvas.revision,
                                 installation_uuid: Canvas.installation_uuid } }
    end
  end

  def health_prognosis
    # do some checks on things that aren't a problem yet, but will be if nothing is done to fix them
    checks = {
      'messages_partition' => Messages::Partitioner.processed?,
      'quizzes_submission_events_partition' => Quizzes::QuizSubmissionEventPartitioner.processed?,
      'versions_partition' => Version::Partitioner.processed?,
    }
    failed = checks.reject{|_k, v| v}.map(&:first)
    if failed.any?
      render :json => {:status => "failed upcoming health checks - #{failed.join(", ")}"}, :status => :internal_server_error
    else
      render :json => {:status => "canvas will be ok, probably"}
    end
  end

  def readiness
    # This action provides a clear signal for assessing system components that are "owned"
    # by Canvas and are ultimately responsible for being alive and able to serve consumer traffic
    #
    # Readiness Checks
    #
    # returns a PrefixProxy instance, treated as truthy
    consul = -> { DynamicSettings.find(tree: :private)[:readiness].nil? }
    # ensures brandable_css_bundles_with_deps exists, returns a string (path), treated as truthy
    css = -> { css_url_for("common") }
    # returns the value of the block <integer>, treated as truthy
    filesystem = -> do
      Tempfile.open('readiness', ENV['TMPDIR'] || Dir.tmpdir) { |f| f.write('readiness') }
    end
    # returns a boolean
    jobs = -> { Delayed::Job.connection.active? }
    # ensures webpack worked; returns a string, treated as truthy
    js = -> { ActionController::Base.helpers.javascript_url("#{js_base_url}/common") }
    # returns a boolean
    postgres = -> { Account.connection.active? }
    # nil response treated as truthy
    redis = -> { MultiCache.cache.fetch('readiness').nil? }
    # ensures `gulp rev` has ran; returns a string, treated as truthy
    rev_manifest = -> { Canvas::Cdn::RevManifest.gulp_manifest.values.first }

    components = {
      common_css: readiness_check(css),
      common_js: readiness_check(js),
      consul: readiness_check(consul),
      filesystem: readiness_check(filesystem),
      jobs: readiness_check(jobs),
      postgresql: readiness_check(postgres),
      redis: readiness_check(redis),
      rev_manifest: readiness_check(rev_manifest)
    }

    failed = components.reject { |_k, v| v[:status] }.map(&:first)
    render_readiness_json(components, failed.any? ? 503 : 200)
  end

  def readiness_check(component)
    begin
      status = false
      time = Benchmark.ms { status = component.call }
    rescue => e
      Canvas::Errors.capture_exception(:readiness, e, :error)
    end

    { time: time, status: status }
  end

  def render_readiness_json(components, status_code)
    render json: {
             status: status_code,
             components:
               components.map do |k, v|
                 name = k
                 status = v[:status] ? 200 : 503
                 time = v[:time]
                 { 'name' => name, 'status' => status, 'response_time_ms' => time }
               end
           },
           status: status_code
  end

  private :readiness_check, :render_readiness_json

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
        @unauthorized_reason = :unpublished if params[:reason] == 'unpublished'
        @needs_cookies = true if params[:reason] == 'needs_cookies'
        return render_unauthorized_action
      when 422
        raise ActionController::InvalidAuthenticityToken.new('test_error')
      else
        @not_found_message = '(test_error message details)' if params[:message].present?
        raise RequestError.new('test_error', params[:status].to_i)
      end
    end

    render status: 404, template: "shared/errors/404_message"
  end

  def web_app_manifest
    # brand_variable returns a value that we expect to go through a rails
    # asset helper, so we need to do that manually here
    icon = helpers.image_path(brand_variable('ic-brand-apple-touch-icon'))
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
end
