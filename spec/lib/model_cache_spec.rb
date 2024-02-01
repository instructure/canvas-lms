# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe ModelCache do
  before do
    # these classes must be real constants because their name is accessed when cacheable_method is called
    class TestModelCacheUser < ActiveRecord::Base # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
      self.table_name = :users # reuse existing tables so AR doesn't asplode
      include ModelCache
    end

    class TestModelCachePseudonym < ActiveRecord::Base # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
      self.table_name = :pseudonyms
      include ModelCache

      belongs_to :test_model_cache_user, foreign_key: :user_id
      cacheable_method :test_model_cache_user, key_method: :user_id

      belongs_to :test_model_cache_user_copy, class_name: "TestModelCacheUser", foreign_key: :user_id
    end
  end

  before do
    user_with_pseudonym(name: "qwerty")
    @user = TestModelCacheUser.where(id: @user).first
    @pseudonym = TestModelCachePseudonym.where(id: @pseudonym).first
  end

  after do
    ModelCache.keys.delete("TestModelCacheUser")
    ModelCache.keys.delete("TestModelCachePseudonym")
    # rubocop:disable RSpec/RemoveConst
    Object.send(:remove_const, :TestModelCacheUser)
    Object.send(:remove_const, :TestModelCachePseudonym)
    # rubocop:enable RSpec/RemoveConst
  end

  it "does not cache by default" do
    u1 = @pseudonym.test_model_cache_user
    expect(u1).to eql(@user)
    expect(u1).not_to equal(@user)
  end

  context "with_cache" do
    it "caches configured instance lookups" do
      ModelCache.with_cache(test_model_cache_users: [@user]) do
        expect(@pseudonym.test_model_cache_user).to equal(@user)
      end
    end

    it "does not cache any other lookups" do
      ModelCache.with_cache(test_model_cache_users: [@user]) do
        u2 = @pseudonym.test_model_cache_user_copy
        expect(u2).to eql(@user)
        expect(u2).not_to equal(@user)
      end
    end
  end
end
