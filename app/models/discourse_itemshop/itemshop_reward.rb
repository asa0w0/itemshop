# frozen_string_literal: true

module ::DiscourseItemshop
  class ItemshopReward < ActiveRecord::Base
    self.table_name = "itemshop_rewards"

    enum :reward_type, { manual: 0, title: 1, group: 2, avatar_frame: 3 }, scopes: false
    enum :rarity, { common: 0, rare: 1, exotic: 2, legendary: 3 }, suffix: true

    validates :name, presence: true
    validates :category, presence: true
    validates :cost, numericality: { greater_than_or_equal_to: 0 }
  end
end
