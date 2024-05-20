# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class ReleaseNotesController < ApplicationController
  before_action :get_context, only: %w[manage]
  before_action :require_manage_release_notes, except: %w[latest unread_count]

  def require_manage_release_notes
    require_site_admin_with_permission(:manage_release_notes)
  end

  def index
    notes = Api.paginate(ReleaseNote.paginated(include_langs: include_langs?), self, api_v1_release_notes_url)
    render json: notes.to_json(except: include_langs? ? [] : ["langs"])
  end

  def create
    upsert(ReleaseNote.new)
  end

  def update
    upsert(ReleaseNote.find(params.require(:id), include_langs: true))
  end

  def upsert(note)
    note.target_roles = upsert_params[:target_roles] if upsert_params[:target_roles]
    upsert_params[:show_ats]&.each { |env, time| note.set_show_at(env, Time.parse(time).utc) }
    note.published = upsert_params[:published] if upsert_params.key?(:published)
    upsert_params[:langs]&.each do |lang, data|
      note[lang] = data
    end
    note.save

    render json: note.to_json
  end

  def destroy
    note = ReleaseNote.find(params.require(:id), include_langs: true)
    note.delete

    render json: { status: "ok" }
  end

  def publish
    note = ReleaseNote.find(params.require(:id))
    note.published = true
    note.save
  end

  def unpublish
    note = ReleaseNote.find(params.require(:id))
    note.published = false
    note.save
  end

  def latest
    transformed_notes = release_notes_for_user.map do |note|
      localized_text = note[release_note_lang] || note["en"]
      {
        id: note.id,
        title: localized_text[:title],
        description: localized_text[:description],
        url: localized_text[:url],
        date: note.show_ats[release_note_env],
        new: note.show_ats[release_note_env] > last_seen_release_note
      }
    end

    if !(@current_user.nil? || transformed_notes.empty?) && (transformed_notes.first[:date] > last_seen_release_note)
      @current_user.last_seen_release_note = transformed_notes.first[:date]
      @current_user.save!
    end

    render json: transformed_notes
  end

  def unread_count
    render json: {
      unread_count: release_notes_for_user.count { |rn| rn.show_ats[release_note_env] > last_seen_release_note }
    }
  end

  def manage
    raise ActiveRecord::RecordNotFound unless @context.site_admin?

    @page_title = t("Canvas Release Notes")
    js_bundle :release_notes_edit
    set_active_tab "release_notes"
    js_env({
             release_notes_langs: allowed_langs,
             release_notes_envs: allowed_envs,
           })
    render html: "".html_safe, layout: true
  end

  private

  def release_notes_for_user
    return [] unless ReleaseNote.enabled?

    # Treat anonymous users as regular "user"
    roles = @current_user&.roles(@domain_root_account) || ["user"]

    all_notes = roles.flat_map do |role|
      # Caches are partitioned by environment anyways so don't include in the key
      # Since the time to show new notes could roll over at any time, just refresh the latest
      # notes per role every 5 minutes
      MultiCache.fetch("latest_release_notes/#{role}/#{release_note_lang}", expires_in: 300) do
        notes = ReleaseNote.latest(env: release_note_env, role:, limit: latest_limit)
        # Ensure we have loaded the locales *before* caching
        notes.each { |note| note[release_note_lang] || note["en"] }
        notes
      end
    end

    all_notes.sort_by { |note| note.show_ats[release_note_env] }.reverse!.first(latest_limit)
  end

  def last_seen_release_note
    # for an anonymous user, they have always seen everything
    @last_seen_release_note ||= @current_user&.last_seen_release_note || Time.now
  end

  def release_note_lang
    @release_note_lang ||= I18n.fallbacks[I18n.locale].detect { |locale| allowed_langs.include?(locale.to_s) }
  end

  def release_note_env
    Canvas.environment.downcase
  end

  def upsert_params
    @upsert_params ||= params.permit(:published, target_roles: [], langs: allowed_langs.index_with { %w[title description url] }, show_ats: allowed_envs).to_h
  end

  def allowed_langs
    Setting.get("release_notes_langs", "en,es,pt,nn,nl,zh").split(",")
  end

  def allowed_envs
    Setting.get("release_notes_envs", Rails.env.production? ? "beta,production" : Rails.env).split(",")
  end

  def latest_limit
    10
  end

  def include_langs?
    !!params[:includes]&.include?("langs")
  end
end
