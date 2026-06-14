# frozen_string_literal: true

module ::DiscourseItemshop
  class ItemshopInventoryItemSerializer < ::ApplicationSerializer
    attributes :id, :user_id, :equipped, :status, :created_at, :purchased_by_username

    has_one :reward, serializer: ::DiscourseItemshop::ItemshopRewardSerializer, embed: :objects

    def purchased_by_username
      object.purchased_by_user&.username
    end
  end
end
