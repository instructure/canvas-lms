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
  skip_before_action :load_account, :only => :health_check
  skip_before_action :load_user, :only => [:health_check, :browserconfig]

  def styleguide
    js_bundle :styleguide
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
    Account.connection.select_value("SELECT 1")
    if Delayed::Job == Delayed::Backend::ActiveRecord::Job
      Delayed::Job.connection.select_value("SELECT 1") unless Account.connection == Delayed::Job.connection
    end
    Tempfile.open("heartbeat", ENV['TMPDIR'] || Dir.tmpdir) { |f| f.write("heartbeat"); f.flush }

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

  # for windows live tiles
  def browserconfig
    cancel_cache_buster
    expires_in 10.minutes, public: true
  end

  def test_error
    render status: 404, template: "shared/errors/404_message"
  end
end
