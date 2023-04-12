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
