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
#

describe CanvasCareer::UserPreferenceManager do
  let(:session) { {} }
  let(:manager) { described_class.new(session) }

  describe "experience preferences" do
    it "defaults to academic experience" do
      expect(manager.prefers_academic?).to be true
      expect(manager.prefers_career?).to be false
    end

    it "can switch to career experience" do
      manager.save_preferred_experience(CanvasCareer::Constants::Experience::CAREER)
      expect(manager.prefers_career?).to be true
      expect(manager.prefers_academic?).to be false
    end

    it "ignores invalid experience values" do
      manager.save_preferred_experience("invalid_experience")
      expect(manager.prefers_academic?).to be true # remains default
    end
  end

  describe "role preferences" do
    it "defaults to learning provider role" do
      expect(manager.prefers_learning_provider?).to be true
      expect(manager.prefers_learner?).to be false
    end

    it "can switch to learner role" do
      manager.save_preferred_role(CanvasCareer::Constants::Role::LEARNER)
      expect(manager.prefers_learner?).to be true
      expect(manager.prefers_learning_provider?).to be false
    end

    it "ignores invalid role values" do
      manager.save_preferred_role("invalid_role")
      expect(manager.prefers_learning_provider?).to be true # remains default
    end
  end

  describe "session management" do
    it "persists preferences in the session" do
      manager.save_preferred_experience(CanvasCareer::Constants::Experience::ACADEMIC)
      manager.save_preferred_role(CanvasCareer::Constants::Role::LEARNER)

      new_manager = described_class.new(session)
      expect(new_manager.prefers_academic?).to be true
      expect(new_manager.prefers_learner?).to be true
    end
  end
end
