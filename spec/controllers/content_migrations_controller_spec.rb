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

require_relative "../helpers/k5_common"

describe ContentMigrationsController do
  include K5Common

  context "course" do
    before(:once) do
      course_factory active_all: true
    end

    let(:migration) do
      migration = @course.content_migrations.build(migration_settings: {})
      migration.save!
      migration
    end

    describe "#index" do
      before do
        user_session(@teacher)
      end

      it "exports quizzes_next environment" do
        get :index, params: { course_id: @course.id }
        expect(response).to be_successful
        expect(assigns[:js_env][:NEW_QUIZZES_IMPORT]).not_to be_nil
        expect(assigns[:js_env][:QUIZZES_NEXT_ENABLED]).not_to be_nil
      end

      it "loads classic theming in a classic course" do
        get :index, params: { course_id: @course.id }
        expect(assigns(:css_bundles)).to be_nil
        expect(assigns(:js_bundles)).to be_nil
      end

      it "loads k5 theming in a k5 course" do
        toggle_k5_setting(@course.account)
        get :index, params: { course_id: @course.id }
        expect(assigns(:css_bundles).flatten).to include(:k5_theme)
        expect(assigns(:js_bundles).flatten).to include(:k5_theme)
      end

      context "instui_for_import_page flag" do
        it "exports proper environment variables with the flag OFF" do
          Account.site_admin.disable_feature!(:instui_for_import_page)
          get :index, params: { course_id: @course.id }
          expect(assigns[:js_env][:EXTERNAL_TOOLS]).not_to be_nil
          expect(assigns[:js_env][:UPLOAD_LIMIT]).not_to be_nil
          expect(assigns[:js_env][:SELECT_OPTIONS]).not_to be_nil
          expect(assigns[:js_env][:QUESTION_BANKS]).not_to be_nil
          expect(assigns[:js_env][:COURSE_ID]).not_to be_nil
          expect(assigns[:js_env][:CONTENT_MIGRATIONS]).not_to be_nil
          expect(assigns[:js_env][:SHOW_SELECT]).not_to be_nil
          expect(assigns[:js_env][:CONTENT_MIGRATIONS_EXPIRE_DAYS]).not_to be_nil
          expect(assigns[:js_env][:QUIZZES_NEXT_ENABLED]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_IMPORT]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_MIGRATION]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_MIGRATION_DEFAULT]).not_to be_nil
          expect(assigns[:js_env][:SHOW_SELECTABLE_OUTCOMES_IN_IMPORT]).not_to be_nil
        end

        it "exports proper environment variables with the flag ON" do
          Account.site_admin.enable_feature!(:instui_for_import_page)
          get :index, params: { course_id: @course.id }
          expect(assigns[:js_env][:EXTERNAL_TOOLS]).to be_nil
          expect(assigns[:js_env][:UPLOAD_LIMIT]).not_to be_nil
          expect(assigns[:js_env][:SELECT_OPTIONS]).to be_nil
          expect(assigns[:js_env][:QUESTION_BANKS]).not_to be_nil
          expect(assigns[:js_env][:COURSE_ID]).not_to be_nil
          expect(assigns[:js_env][:CONTENT_MIGRATIONS]).to be_nil
          expect(assigns[:js_env][:SHOW_SELECT]).to be_nil
          expect(assigns[:js_env][:CONTENT_MIGRATIONS_EXPIRE_DAYS]).to be_nil
          expect(assigns[:js_env][:QUIZZES_NEXT_ENABLED]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_IMPORT]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_MIGRATION]).not_to be_nil
          expect(assigns[:js_env][:NEW_QUIZZES_MIGRATION_DEFAULT]).not_to be_nil
          expect(assigns[:js_env][:SHOW_SELECTABLE_OUTCOMES_IN_IMPORT]).to be_nil
        end
      end
    end

    describe "#show" do
      context "params[:include] present" do
        it "shows content migration with audit_info" do
          user_session(@teacher)
          get :show, params: {
            course_id: @course.id,
            id: migration.id,
            include: ["audit_info"]
          }
          expect(response).to be_successful
          expect(response.body).to include("audit_info")
        end
      end

      context "params[:include] not present" do
        it "shows content migration without audit_info" do
          user_session(@teacher)
          get :show, params: {
            course_id: @course.id,
            id: migration.id
          }
          expect(response).to be_successful
          expect(response.body).not_to include("audit_info")
        end
      end
    end
  end
end
