#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe RoleListsController do

  before { sign_in(people(:top_leader)) }

  let(:group)   { groups(:top_group) }
  let(:person1) { role1.person }
  let(:person2) { role2.person }
  let!(:role1)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }
  let!(:role2)  { Fabricate(Group::TopGroup::Member.name.to_sym, group: group) }

  context 'authorization' do

    before do
      sign_in(people(:bottom_member))
    end

    it 'PUT update' do
      expect do
        put :update, group_id: group,
          ids: person1.id, 
          moving_role_type: Group::TopGroup::Member,
          role: { type: Group::TopGroup::Leader,
                  group_id: group }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'DELETE destroy' do
      expect do
        delete :destroy, group_id: group,
          ids: person1.id, 
          role: { type: Group::TopGroup::Member }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'POST create' do
      expect do
        post :create, group_id: group,
          ids: person1.id, 
          role: { type: Group::TopGroup::Member }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'DELETE destroy' do
    it 'only removes one role' do
      expect do
        delete :destroy, group_id: group,
          ids: person1.id, 
          role: { type: Group::TopGroup::Member }
      end.to change(Role, :count).by(-1)
      
      expect(flash[:notice]).to include 'Eine Rolle wurde gelöscht'
    end

    it 'may remove multiple roles' do
      expect do
        delete :destroy, group_id: group,
          ids: [person1.id, person2.id].join(','),
          role: { type: Group::TopGroup::Member }
      end.to change(Role, :count).by(-2)
      
      expect(flash[:notice]).to include '2 Rollen wurden gelöscht'
    end
  end

  context 'POST create' do
    it 'creates only one role for one person' do
      expect do
        post :create, group_id: group,
          ids: person1.id, 
          role: { type: Group::TopGroup::Member }
      end.to change(Role, :count).by(1)

      expect(flash[:notice]).to include 'Eine Rolle wurde erstellt'
    end

    it 'may create multiple roles' do
      expect do
        post :create, group_id: group,
          ids: [person2.id, person1.id].join(','), 
          role: { type: Group::TopGroup::Member }
      end.to change(Role, :count).by(2)

      expect(flash[:notice]).to include '2 Rollen wurden erstellt'
    end
  end

  context 'GET move' do
    it 'sets instance variables correctly' do
      ids = [person2.id, person1.id].join(',')
      xhr :get, :move, group_id: group,
          ids: ids,
          role: { type: Group::TopGroup::Member }

      expect(assigns(:moving_people)).to eq(ids)
      expect(assigns(:moving_role_type)).to eq('Group::TopGroup::Member')
      expect(assigns(:moving_roles_count)).to eq(2)
    end
  end

  context 'PUT update' do
    it 'fails on invalid role type' do
      put :update, group_id: group,
        ids: person1.id, 
        moving_role_type: Group::TopGroup::Member,
        role: { type: 'invalid',
                group_id: group }

      expect(flash[:alert]).to include 'Bitte geben Sie eine valide Rolle an'
    end

    it 'change role type of one role' do
      put :update, group_id: group,
        ids: person1.id, 
        moving_role_type: Group::TopGroup::Member,
        role: { type: Group::TopGroup::Leader,
                group_id: group }

      role = person1.roles.first
      expect(role.group).to eq(group)
      expect(role.type).to eq('Group::TopGroup::Leader')
    end

    it 'may change multiple role types' do
      put :update, group_id: group,
        ids: [person1.id, person2.id].join(','), 
        moving_role_type: Group::TopGroup::Member,
        role: { type: Group::TopGroup::Leader,
                group_id: group }

      role1 = person1.roles.first
      role2 = person2.roles.first

      [role1, role2].each do |role|
        expect(role.group).to eq(group)
        expect(role.type).to eq('Group::TopGroup::Leader')
      end
    end

    it 'may move multiple roles into another group and changes type' do
      put :update, group_id: group,
        ids: [person1.id, person2.id].join(','), 
        moving_role_type: Group::TopGroup::Member,
        role: { type: Group::TopLayer::TopAdmin,
                group_id: groups(:top_layer) }

      role1 = person1.roles.first
      role2 = person2.roles.first

      [role1, role2].each do |role|
        expect(role.group).to eq(groups(:top_layer))
        expect(role.type).to eq('Group::TopLayer::TopAdmin')
      end
    end
  end
  
end
