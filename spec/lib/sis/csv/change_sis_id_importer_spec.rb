#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::ChangeSisIdImporter do

  before {account_model}

  it 'should change values of sis ids' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    p1 = u1.pseudonym
    a = Account.create(parent_account: @account, name: 'English')
    a.sis_source_id = 'sub1'
    a.save!
    c = course_model(account: @account)
    c.sis_source_id = 'c001'
    c.save!
    cs = c.course_sections.create(name: 'section1')
    cs.sis_source_id = 's001'
    cs.save!
    t = @account.enrollment_terms.create(name: 'term1')
    t.sis_source_id = 'term1'
    t.save!
    process_csv_data_cleanly(
      'old_id,new_id,type',
      'U001,u00a,user',
      'sub1,sub_a,Account',
      'c001,c_a,COURSE',
      's001,s_a,Section ',
      'term1,term_a,term'
    )
    expect(p1.reload.sis_user_id).to eq 'u00a'
    expect(a.reload.sis_source_id).to eq 'sub_a'
    expect(c.reload.sis_source_id).to eq 'c_a'
    expect(cs.reload.sis_source_id).to eq 's_a'
    expect(t.reload.sis_source_id).to eq 'term_a'
  end

  it 'should give errors and warnings' do
    c = course_model(account: @account)
    c.sis_source_id = 'c001'
    c.save!
    c2 = course_model(account: @account)
    c2.sis_source_id = 'c002'
    c2.save!
    importer = process_csv_data(
      'old_id,new_id,type',
      'invalid,valid,term',
      ',blank,term',
      'blank,,term',
      'c_a,blank,',
      'c002,c001,course',
      'c001,new_id,invalid'
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["An old_id, 'invalid', referenced a non-existent term and was not changed.",
                            "No old_id or old_integration_id given for change_sis_id",
                            "No new_id or new_integration_id given for change_sis_id",
                            "No type given for change_sis_id",
                            "A new_id, 'c001', referenced an existing course and the course with sis_source_id 'c002' was not updated",
                            "Invalid type 'invalid' for change_sis_id"]
  end

  it 'should allow removing user.integration_ids' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    p1 = u1.pseudonym
    p1.integration_id = 'int1'
    p1.save!
    process_csv_data_cleanly(
      'old_integration_id,new_integration_id,type',
      'int1,<delete>,user'
    )
    expect(p1.reload.integration_id).to be_nil
  end

  it 'should allow changing integration_ids' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    p1 = u1.pseudonym
    p1.integration_id = 'int1'
    p1.save!
    process_csv_data_cleanly(
      'old_integration_id,new_integration_id,type',
      'int1,int2,user'
    )
    expect(p1.reload.integration_id).to eq('int2')
  end

  it 'should change both SIS ID and integration ID' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    p1 = u1.pseudonym
    p1.integration_id = 'int1'
    p1.save!
    process_csv_data_cleanly(
      'old_id,new_id,old_integration_id,new_integration_id,type',
      'U001,sis2,int1,int2,user'
    )
    expect(p1.reload.integration_id).to eq('int2')
    expect(p1.sis_user_id).to eq('sis2')
  end

  it 'should change both SIS ID and integration ID if only one is passed in' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    p1 = u1.pseudonym
    p1.integration_id = 'int1'
    p1.save!
    process_csv_data_cleanly(
      'new_id,old_integration_id,new_integration_id,type',
      'sis2,int1,int2,user'
    )
    expect(p1.reload.integration_id).to eq('int2')
    expect(p1.sis_user_id).to eq('sis2')
  end

  it 'should throw an error when you pass in mismatched SIS ID and integration ID' do
    u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    u2 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U002')
    u1.pseudonym.update!(integration_id: 'int1')
    u2.pseudonym.update!(integration_id: 'int2')
    importer = process_csv_data(
      'old_id,new_id,old_integration_id,new_integration_id,type',
      'U001,int2,new_integration_id,user'
    )
    expect(importer.errors).not_to be_nil
  end

  describe 'group categories' do
    let!(:gc) {group_category(context: @account, sis_source_id: 'GC1')}

    it 'should change the sis id for a group category' do
      importer = process_csv_data(
        'old_id,new_id,type',
        'GC1,GC2,group_category'
      )
      expect(importer.errors).to be_empty
      gc.reload
      expect(gc.sis_source_id).to eq('GC2')
    end

    it 'should not error if other rows have an integration_id' do
      u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
      u1.pseudonym.integration_id = 'int1'
      u1.pseudonym.save!

      importer = process_csv_data(
        'old_id,new_id,old_integration_id,new_integration_id,type',
        ',,int1,int2,user',
        'GC1,GC2,,,group_category'
      )
      gc.reload
      expect(gc.sis_source_id).to eq('GC2')
    end

    it 'should cleanly handle error if integration_id is given' do
      u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')

      importer = process_csv_data(
        'old_id,new_integration_id,new_id,type',
        'GC1,INTID,group_category',
        'U001,,U002,user'
      )
      expect(importer.errors).not_to be_empty
      u1.reload
      expect(u1.pseudonym.sis_user_id).to eq('U002')
    end
  end
end
