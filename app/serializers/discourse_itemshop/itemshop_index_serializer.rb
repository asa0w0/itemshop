# frozen_string_literal: true

module ::DiscourseItemshop
  class ItemshopIndexSerializer < ::ApplicationSerializer
    attributes :balance, :categories_with_counts

    has_many :rewards, serializer: ::DiscourseItemshop::ItemshopRewardSerializer, embed: :objects
    has_many :inventory, serializer: ::DiscourseItemshop::ItemshopInventoryItemSerializer, embed: :objects
    has_many :featured_rewards, serializer: ::DiscourseItemshop::ItemshopRewardSerializer, embed: :objects

    def balance
      object[:balance]
    end

    def rewards
      object[:rewards]
    end

    def inventory
      object[:inventory]
    end

    def categories_with_counts
      object[:categories_with_counts]
    end

    def featured_rewards
      object[:featured_rewards]
    end
  end
end
