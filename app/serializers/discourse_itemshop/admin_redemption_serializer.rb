# frozen_string_literal: true

module ::DiscourseItemshop
  class AdminRedemptionSerializer < ::ApplicationSerializer
    attributes :id, :status, :created_at

    has_one :user, serializer: ::BasicUserSerializer, embed: :objects
    has_one :reward, serializer: ::DiscourseItemshop::ItemshopRewardSerializer, embed: :objects
  end
end
