# frozen_string_literal: true

class CreateItemshopTables < ActiveRecord::Migration[7.0]
  def change
    create_table :itemshop_rewards do |t|
      t.string :name, null: false
      t.string :description
      t.integer :cost, null: false
      t.integer :reward_type, null: false, default: 0
      t.string :reward_value
      t.string :icon, null: false, default: "gift"
      t.string :category, null: false, default: "Sonstiges"
      t.integer :rarity, null: false, default: 0
      t.timestamps
    end

    create_table :itemshop_inventory_items do |t|
      t.integer :user_id, null: false
      t.integer :reward_id, null: false
      t.integer :purchased_by_user_id
      t.string :status, null: false, default: "delivered"
      t.boolean :equipped, null: false, default: false
      t.timestamps
    end

    add_index :itemshop_inventory_items, :user_id
    add_index :itemshop_inventory_items, [:user_id, :equipped]
  end
end
