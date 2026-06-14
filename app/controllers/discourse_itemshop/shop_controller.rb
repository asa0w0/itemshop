# frozen_string_literal: true

module ::DiscourseItemshop
  class ShopController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in, except: [:user_inventory]

    def index
      rewards = ItemshopReward.all.order(cost: :asc)
      inventory = ItemshopInventoryItem.where(user_id: current_user.id).includes(:reward)

      categories_with_counts = ItemshopReward.group(:category).count.map do |cat, count|
        { name: cat, count: count }
      end

      featured_rewards = ItemshopReward.order("RANDOM()").limit(9)

      render_serialized(
        {
          rewards: rewards,
          inventory: inventory,
          balance: current_user.gamification_score,
          categories_with_counts: categories_with_counts,
          featured_rewards: featured_rewards
        },
        ItemshopIndexSerializer,
        root: false
      )
    end

    def buy
      params.require(:reward_id)
      reward = ItemshopReward.find(params[:reward_id])

      if current_user.gamification_score < reward.cost
        return render_json_error(I18n.t("itemshop.shop.insufficient_points"))
      end

      recipient = nil
      if params[:recipient_username].present?
        recipient = User.find_by_username(params[:recipient_username])
        return render_json_error(I18n.t("itemshop.shop.recipient_not_found")) unless recipient
      end

      target_user = recipient || current_user
      inventory_item = nil

      ActiveRecord::Base.transaction do
        # Create negative score event to deduct points from buyer
        description = if recipient
          I18n.t("itemshop.shop.gifted_item", name: reward.name, recipient: recipient.username)
        else
          I18n.t("itemshop.shop.redeemed_item", name: reward.name)
        end

        # Deduct points from current user using DiscourseGamification score event
        ::DiscourseGamification::GamificationScoreEvent.create!(
          user_id: current_user.id,
          date: Date.today,
          points: -reward.cost,
          description: description
        )

        status = reward.manual? ? "pending" : "delivered"

        inventory_item = ItemshopInventoryItem.create!(
          user_id: target_user.id,
          reward_id: reward.id,
          purchased_by_user_id: recipient ? current_user.id : nil,
          status: status,
          equipped: false
        )

        if reward.group?
          group = Group.find_by(id: reward.reward_value.to_i)
          if group
            group.add(target_user)
          end
        end
      end

      # Recalculate scores so the new balance is reflected immediately
      ::DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)

      render_serialized(inventory_item, ItemshopInventoryItemSerializer, root: false)
    end

    def toggle_equip
      params.require(:id)
      inventory_item = ItemshopInventoryItem.find_by(id: params[:id], user_id: current_user.id)
      raise Discourse::NotFound unless inventory_item
      raise Discourse::InvalidAccess unless inventory_item.reward.title? || inventory_item.reward.avatar_frame? || inventory_item.reward.manual?

      if inventory_item.equipped?
        ItemshopInventoryItem.unequip_item(current_user, inventory_item)
      else
        begin
          ItemshopInventoryItem.equip_item(current_user, inventory_item)
        rescue StandardError => e
          return render_json_error(e.message)
        end
      end

      inventory_item.reload
      render_serialized(inventory_item, ItemshopInventoryItemSerializer, root: false)
    end

    def user_inventory
      params.require(:username)
      user = User.find_by_username(params[:username])
      raise Discourse::NotFound unless user

      inventory = ItemshopInventoryItem
        .where(user_id: user.id)
        .where(status: :delivered)
        .includes(:reward)

      render_serialized(inventory, ItemshopInventoryItemSerializer, root: false)
    end
  end
end
