# frozen_string_literal: true

module ::DiscourseItemshop
  class ItemshopInventoryItem < ActiveRecord::Base
    self.table_name = "itemshop_inventory_items"

    belongs_to :user
    belongs_to :reward, class_name: "::DiscourseItemshop::ItemshopReward"
    belongs_to :purchased_by_user, class_name: "::User", optional: true

    enum :status, { pending: "pending", delivered: "delivered", rejected: "rejected" }

    def self.equip_item(user, inventory_item)
      return unless inventory_item.reward.title? || inventory_item.reward.avatar_frame? || inventory_item.reward.manual?

      ActiveRecord::Base.transaction do
        if inventory_item.reward.manual?
          # Enforce showcase limit of 3
          equipped_count = where(user_id: user.id, equipped: true)
            .joins(:reward)
            .where(itemshop_rewards: { reward_type: DiscourseItemshop::ItemshopReward.reward_types[:manual] })
            .count
          if equipped_count >= 3
            raise StandardError.new(I18n.t("itemshop.inventory.showcase_limit_reached", limit: 3))
          end
          inventory_item.update!(equipped: true)
        else
          # Unequip all items of the same type for this user (title/avatar_frame)
          same_type_rewards = ItemshopReward.where(reward_type: inventory_item.reward.reward_type)
          same_type_inventory_items = where(user_id: user.id, reward_id: same_type_rewards.select(:id))
          same_type_inventory_items.update_all(equipped: false)

          # Equip this item
          inventory_item.update!(equipped: true)

          # If it is a title, update user's profile title
          if inventory_item.reward.title?
            user.update!(title: inventory_item.reward.reward_value)
          end
        end
      end
    end

    def self.unequip_item(user, inventory_item)
      return unless inventory_item.reward.title? || inventory_item.reward.avatar_frame? || inventory_item.reward.manual?

      ActiveRecord::Base.transaction do
        inventory_item.update!(equipped: false)

        if inventory_item.reward.title?
          # Only clear if user currently has this title equipped
          if user.title == inventory_item.reward.reward_value
            user.update!(title: nil)
          end
        end
      end
    end
  end
end
