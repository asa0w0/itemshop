# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseItemshop::ShopController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }
  fab!(:leaderboard) { Fabricate(:gamification_leaderboard) }
  fab!(:title_reward) do
    DiscourseItemshop::ItemshopReward.create!(
      name: "Super Hero",
      cost: 50,
      reward_type: :title,
      reward_value: "Hero",
      category: "Manga"
    )
  end
  fab!(:manual_reward) do
    DiscourseItemshop::ItemshopReward.create!(
      name: "T-Shirt",
      cost: 100,
      reward_type: :manual,
      category: "Merchandise"
    )
  end

  before do
    SiteSetting.discourse_gamification_enabled = true
    SiteSetting.discourse_itemshop_enabled = true
    SiteSetting.day_visited_score_value = 0
    sign_in(user)
  end

  describe "#index" do
    it "returns the shop index data successfully" do
      # Give user some points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 200
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      get "/itemshop.json"
      expect(response.status).to eq(200)

      data = response.parsed_body
      expect(data["balance"]).to eq(200)
      expect(data["rewards"].map { |r| r["id"] }).to include(title_reward.id, manual_reward.id)
      expect(data["categories_with_counts"]).to include(
        { "name" => "Manga", "count" => 1 },
        { "name" => "Merchandise", "count" => 1 }
      )
      expect(data["featured_rewards"]).not_to be_nil
      expect(data["inventory"]).to be_empty
    end
  end

  describe "#buy" do
    it "fails if user has insufficient points" do
      post "/itemshop/buy.json", params: { reward_id: manual_reward.id }
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(I18n.t("itemshop.shop.insufficient_points"))
    end

    it "buys a reward successfully if user has enough points" do
      # Give user points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 150
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      initial_score = user.reload.gamification_score

      expect {
        post "/itemshop/buy.json", params: { reward_id: manual_reward.id }
      }.to change { DiscourseItemshop::ItemshopInventoryItem.count }.by(1)

      expect(response.status).to eq(200)

      # Points should be deducted immediately
      DiscourseGamification::LeaderboardCachedView.new(leaderboard).refresh
      user.reload
      expect(user.gamification_score).to eq(initial_score - manual_reward.cost)

      inventory_item = DiscourseItemshop::ItemshopInventoryItem.last
      expect(inventory_item.user_id).to eq(user.id)
      expect(inventory_item.reward_id).to eq(manual_reward.id)
      expect(inventory_item.purchased_by_user_id).to be_nil
      expect(inventory_item.status).to eq("delivered")
    end

    it "gifts a reward successfully to another user" do
      # Give user points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 150
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      initial_score = user.reload.gamification_score

      expect {
        post "/itemshop/buy.json", params: { reward_id: manual_reward.id, recipient_username: other_user.username }
      }.to change { DiscourseItemshop::ItemshopInventoryItem.count }.by(1)

      expect(response.status).to eq(200)

      # Points should be deducted from buyer
      DiscourseGamification::LeaderboardCachedView.new(leaderboard).refresh
      user.reload
      expect(user.gamification_score).to eq(initial_score - manual_reward.cost)

      # Receiver has inventory item
      inventory_item = DiscourseItemshop::ItemshopInventoryItem.last
      expect(inventory_item.user_id).to eq(other_user.id)
      expect(inventory_item.purchased_by_user_id).to eq(user.id)
      expect(inventory_item.status).to eq("pending")
    end
  end

  describe "#toggle_equip" do
    let!(:inventory_item) do
      DiscourseItemshop::ItemshopInventoryItem.create!(
        user_id: user.id,
        reward_id: title_reward.id,
        status: :delivered,
        equipped: false
      )
    end

    it "equips the title and updates user title" do
      post "/itemshop/inventory/#{inventory_item.id}/toggle_equip.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["equipped"]).to be(true)

      user.reload
      expect(user.title).to eq("Hero")
    end

    it "unequips the title and clears user title" do
      inventory_item.update!(equipped: true)
      user.update!(title: "Hero")

      post "/itemshop/inventory/#{inventory_item.id}/toggle_equip.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["equipped"]).to be(false)

      user.reload
      expect(user.title).to be_nil
    end

    it "enforces a maximum limit of 3 equipped manual items" do
      items = 4.times.map do |i|
        r = DiscourseItemshop::ItemshopReward.create!(
          name: "Item #{i}",
          cost: 10,
          reward_type: :manual,
          category: "Manuals"
        )
        DiscourseItemshop::ItemshopInventoryItem.create!(
          user_id: user.id,
          reward_id: r.id,
          status: :delivered,
          equipped: false
        )
      end

      # Equip first 3
      3.times do |i|
        post "/itemshop/inventory/#{items[i].id}/toggle_equip.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["equipped"]).to be(true)
      end

      # 4th should fail with 422 errors limit reached
      post "/itemshop/inventory/#{items[3].id}/toggle_equip.json"
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(I18n.t("itemshop.inventory.showcase_limit_reached", limit: 3))
    end
  end

  describe "#user_inventory" do
    let!(:delivered_item) do
      DiscourseItemshop::ItemshopInventoryItem.create!(
        user_id: other_user.id,
        reward_id: title_reward.id,
        status: :delivered,
        equipped: true
      )
    end
    let!(:pending_item) do
      DiscourseItemshop::ItemshopInventoryItem.create!(
        user_id: other_user.id,
        reward_id: manual_reward.id,
        status: :pending,
        equipped: false
      )
    end

    it "returns public items (delivered status only) for any user" do
      get "/itemshop/user-inventory/#{other_user.username}.json"
      expect(response.status).to eq(200)

      data = response.parsed_body
      expect(data.map { |i| i["id"] }).to contain_exactly(delivered_item.id)
    end
  end
end
