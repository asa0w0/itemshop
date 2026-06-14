# frozen_string_literal: true

DiscourseItemshop::Engine.routes.draw do
  get "/itemshop" => "shop#index"
  post "/itemshop/buy" => "shop#buy"
  post "/itemshop/inventory/:id/toggle_equip" => "shop#toggle_equip"
  get "/itemshop/user-inventory/:username" => "shop#user_inventory"

  scope "/admin/plugins/itemshop", constraints: StaffConstraint.new do
    get "/rewards" => "admin_rewards#rewards"
    post "/rewards" => "admin_rewards#create_reward"
    put "/rewards/:id" => "admin_rewards#update_reward"
    delete "/rewards/:id" => "admin_rewards#delete_reward"
  end
end
