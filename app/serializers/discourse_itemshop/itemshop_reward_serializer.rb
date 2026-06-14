# frozen_string_literal: true

module ::DiscourseItemshop
  class ItemshopRewardSerializer < ::ApplicationSerializer
    attributes :id, :name, :description, :cost, :reward_type, :reward_value, :icon, :rarity, :category
  end
end
