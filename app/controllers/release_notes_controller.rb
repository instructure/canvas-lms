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
  before_action :require_manage_release_notes

  def require_manage_release_notes
    require_site_admin_with_permission(:manage_release_notes)
  end

  def index
    notes = Api.paginate(ReleaseNote.paginated(include_langs: include_langs?), self, api_v1_release_notes_url)
    render json: notes.to_json(except: include_langs? ? [] : ['langs'])
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

    render json: { status: 'ok' }
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

  def manage
    raise ActiveRecord::RecordNotFound unless @context.site_admin?

    @page_title = t('Canvas Release Notes')
    js_bundle :release_notes_edit
    set_active_tab 'release_notes'
    js_env({
      release_notes_langs: allowed_langs,
      release_notes_envs: allowed_envs,
    })
    render :html => "".html_safe, :layout => true
  end

  def upsert_params
    @upsert_params ||= params.permit(:published, target_roles: [], langs: allowed_langs.map { |l| [l, ['title', 'description', 'url']]}.to_h, show_ats: allowed_envs).to_h
  end

  def allowed_langs
    Setting.get('release_notes_langs', 'en,es,pt,nn,nl,zh').split(',')
  end

  def allowed_envs
    Setting.get('release_notes_envs', Rails.env.production? ? 'beta,production' : Rails.env).split(',')
  end

  def include_langs?
    !!params[:includes]&.include?('langs')
  end
end
