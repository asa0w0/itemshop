# name: discourse-itemshop
# about: Dedicated itemshop plugin for Discourse using Gamification score
# version: 0.1.0
# authors: Antigravity
# url: https://github.com/asa0w0/discourse-itemshop
# required_version: 3.3.0

enabled_site_setting :discourse_itemshop_enabled

module ::DiscourseItemshop
  PLUGIN_NAME = "discourse-itemshop"
end

require_relative "lib/discourse_itemshop/engine"

after_initialize do
  Discourse::Application.routes.append do
    mount ::DiscourseItemshop::Engine, at: "/"
  end
  # Rails autoloading will load classes from app/
  
  # Register showcased items on UserCard and User serializers
  add_to_serializer(:user_card, :showcased_items) do
    DiscourseItemshop::ItemshopInventoryItem
      .joins(:reward)
      .where(user_id: object.id, equipped: true, itemshop_rewards: { reward_type: DiscourseItemshop::ItemshopReward.reward_types[:manual] })
      .map { |item| DiscourseItemshop::ItemshopInventoryItemSerializer.new(item, root: false, scope: self.scope).as_json }
  end

  add_to_serializer(:user, :showcased_items) do
    DiscourseItemshop::ItemshopInventoryItem
      .joins(:reward)
      .where(user_id: object.id, equipped: true, itemshop_rewards: { reward_type: DiscourseItemshop::ItemshopReward.reward_types[:manual] })
      .map { |item| DiscourseItemshop::ItemshopInventoryItemSerializer.new(item, root: false, scope: self.scope).as_json }
  end
end
