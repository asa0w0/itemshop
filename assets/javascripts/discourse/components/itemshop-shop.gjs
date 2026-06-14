import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq, or, gt } from "truth-helpers";
import { hash, fn, concat } from "@ember/helper";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import fullnumber from "../helpers/fullnumber";
import ItemDetailModal from "./modal/item-detail";
import GiftItemModal from "./modal/gift-item";

const isEquipping = (equipping, itemId) => equipping[itemId];

export default class ItemshopShop extends Component {
  @service dialog;
  @service router;
  @service modal;
  @service currentUser;

  @tracked selectedMenu = "itemshop"; // "itemshop", "inventory", or category name (e.g. "Manga")
  @tracked balance = this.args.model.balance;
  @tracked inventory = this.args.model.inventory;
  @tracked buying = false;
  @tracked equipping = {};
  @tracked currentPage = 1;

  get rewards() {
    return this.args.model.rewards || [];
  }

  get categories() {
    return this.args.model.categories_with_counts || [];
  }

  get featuredRewards() {
    return this.args.model.featured_rewards || [];
  }

  get isBalanceLessThanCost() {
    return (rewardCost) => this.balance < rewardCost;
  }

  get isStaff() {
    return this.currentUser?.staff || false;
  }

  // Filter rewards by selected category
  get filteredRewards() {
    return this.rewards.filter((r) => r.category === this.selectedMenu);
  }

  // Paginated rewards
  get paginatedRewards() {
    const start = (this.currentPage - 1) * 6;
    return this.filteredRewards.slice(start, start + 6);
  }

  get totalPages() {
    return Math.ceil(this.filteredRewards.length / 6);
  }

  get pageNumbers() {
    const pages = [];
    for (let i = 1; i <= this.totalPages; i++) {
      pages.push(i);
    }
    return pages;
  }

  @action
  selectMenu(menuName) {
    this.selectedMenu = menuName;
    this.currentPage = 1;
  }

  @action
  setPage(page) {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
    }
  }

  @action
  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage += 1;
    }
  }

  @action
  openDetails(reward) {
    this.modal.show(ItemDetailModal, {
      model: {
        reward: reward,
        balance: this.balance,
        buyItem: this.buyItem.bind(this),
        giftItem: this.openGiftModal.bind(this),
      },
    });
  }

  @action
  openGiftModal(reward) {
    this.modal.show(GiftItemModal, {
      model: {
        reward: reward,
        buyItem: this.buyItem.bind(this),
      },
    });
  }

  buyItem(reward, recipientUsername = null) {
    if (this.buying) {
      return;
    }
    this.buying = true;

    const data = { reward_id: reward.id };
    if (recipientUsername) {
      data.recipient_username = recipientUsername;
    }

    ajax("/itemshop/buy", {
      type: "POST",
      data: data,
    })
      .then((newItem) => {
        this.balance -= reward.cost;
        if (recipientUsername) {
          this.dialog.alert({
            message: i18n("itemshop.shop.gift_send_success", {
              name: reward.name,
              recipient: recipientUsername,
            }),
          });
        } else {
          this.inventory = [newItem, ...this.inventory];
        }
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.buying = false;
      });
  }

  @action
  toggleEquip(item) {
    if (this.equipping[item.id]) {
      return;
    }
    this.equipping = { ...this.equipping, [item.id]: true };

    ajax(`/itemshop/inventory/${item.id}/toggle_equip`, {
      type: "POST",
    })
      .then((updatedItem) => {
        this.inventory = this.inventory.map((invItem) => {
          if (invItem.id === updatedItem.id) {
            return updatedItem;
          }
          return invItem;
        });
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.equipping = { ...this.equipping, [item.id]: false };
      });
  }

  <template>
    <div class="itemshop-outer-container">
      <div class="itemshop-grid-container">
        
        <!-- Linke Seitenleiste (Sidebar Navigation & Kategorien) -->
        <aside class="itemshop-sidebar">
          <div class="sidebar-section">
            <ul class="sidebar-menu-list">
              <li>
                <button
                  class="sidebar-menu-btn {{if (eq this.selectedMenu 'itemshop') 'active'}}"
                  type="button"
                  {{on "click" (fn this.selectMenu "itemshop")}}
                >
                  {{icon "store"}} Itemshop
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "piggy-bank"}} Schweinchen Lotterie
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "box-open"}} Booster Packs
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "images"}} Sammlungen
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "shop"}} Marktplatz
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "right-left"}} Handeln
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "list"}} Item-Listen
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "list-check"}} Meine Listen
                </button>
              </li>
              <li>
                <button
                  class="sidebar-menu-btn {{if (eq this.selectedMenu 'inventory') 'active'}}"
                  type="button"
                  {{on "click" (fn this.selectMenu "inventory")}}
                >
                  {{icon "box-archive"}} Meine Items
                </button>
              </li>
              <li>
                <button class="sidebar-menu-btn inactive" type="button" disabled>
                  {{icon "clock-rotate-left"}} Letzte Aktivitäten
                </button>
              </li>
            </ul>
          </div>

          <div class="sidebar-section categories-section">
            <h4 class="sidebar-title">Kategorien</h4>
            <ul class="sidebar-menu-list">
              {{#each this.categories as |cat|}}
                <li>
                  <button
                    class="sidebar-menu-btn {{if (eq this.selectedMenu cat.name) 'active'}}"
                    type="button"
                    {{on "click" (fn this.selectMenu cat.name)}}
                  >
                    <span class="category-name">{{cat.name}}</span>
                    <span class="category-count">{{cat.count}}</span>
                  </button>
                </li>
              {{/each}}
            </ul>
          </div>
        </aside>

        <!-- Hauptinhaltsbereich -->
        <main class="itemshop-main-content">
          <div class="shop-header-row">
            <div class="shop-balance-pill">
              {{icon "award"}}
              <span class="balance-text">Guthaben: <strong>{{fullnumber this.balance}} Münzen</strong></span>
            </div>
            {{#if this.isStaff}}
              <a href="/admin/plugins/itemshop" class="btn btn-default admin-quick-link" target="_blank">
                {{icon "wrench"}} Itemshop verwalten
              </a>
            {{/if}}
          </div>

          {{#if (eq this.selectedMenu "itemshop")}}
            <!-- Landing-Page: Kennst du schon...? Featured Modul -->
            <div class="itemshop-landing-page">
              <h1 class="page-main-title">Itemshop</h1>

              <div class="featured-items-block">
                <h3 class="block-title">Kennst du schon ... ?</h3>
                <div class="featured-grid">
                  {{#each this.featuredRewards as |reward|}}
                    <button
                      class="featured-item-card"
                      type="button"
                      {{on "click" (fn this.openDetails reward)}}
                    >
                      <div class="card-icon-wrapper rarity-{{reward.rarity}}">
                        {{icon reward.icon}}
                      </div>
                      <div class="card-info">
                        <span class="card-name">{{reward.name}}</span>
                        {{#if reward.description}}
                          <span class="card-desc">{{reward.description}}</span>
                        {{/if}}
                        <div class="card-footer">
                          <span class="card-cost">
                            {{icon "award"}} {{fullnumber reward.cost}} Münzen
                          </span>
                        </div>
                      </div>
                    </button>
                  {{/each}}
                </div>
              </div>
            </div>

          {{else if (eq this.selectedMenu "inventory")}}
            <!-- Benutzer-Inventar (Meine Items) -->
            <div class="itemshop-inventory-page">
              <h1 class="page-main-title">Meine Items</h1>

              {{#if this.inventory.length}}
                <div class="shop-catalog-grid">
                  {{#each this.inventory as |item|}}
                    <div class="shop-catalog-card {{if item.equipped 'equipped'}} rarity-{{item.reward.rarity}}">
                      <div class="card-icon-wrapper">
                        {{icon item.reward.icon}}
                        {{#if item.equipped}}
                          <span class="equipped-check-badge">{{icon "check"}}</span>
                        {{/if}}
                      </div>
                      <h3 class="card-name">{{item.reward.name}}</h3>
                      <p class="card-desc">{{item.reward.description}}</p>
                      
                      {{#if item.purchased_by_username}}
                        <span class="gifted-label">Geschenk von @{{item.purchased_by_username}}</span>
                      {{/if}}

                      <div class="card-action-bar">
                        <span class="status-label status-{{item.status}}">
                          {{i18n (concat "itemshop.shop.status_" item.status)}}
                        </span>

                        <DButton
                          @action={{fn this.toggleEquip item}}
                          @disabled={{isEquipping this.equipping item.id}}
                          class={{if item.equipped "btn-danger unequip-btn" "btn-primary equip-btn"}}
                          @label={{if item.equipped "itemshop.inventory.unequip" "itemshop.inventory.equip"}}
                        />
                      </div>
                    </div>
                  {{/each}}
                </div>
              {{else}}
                <div class="empty-shop-state">
                  {{icon "box-archive"}}
                  <p>{{i18n "itemshop.inventory.empty_inventory"}}</p>
                </div>
              {{/if}}
            </div>

          {{else}}
            <!-- Kategorien-Katalogseite -->
            <div class="itemshop-catalog-page">
              <h1 class="page-main-title">{{this.selectedMenu}}</h1>

              <div class="catalog-filters-row">
                <span class="results-count">{{this.filteredRewards.length}} Gegenstände gefunden</span>
              </div>

              {{#if this.paginatedRewards.length}}
                <div class="shop-catalog-grid">
                  {{#each this.paginatedRewards as |reward|}}
                    <button
                      class="shop-catalog-card rarity-{{reward.rarity}}"
                      type="button"
                      {{on "click" (fn this.openDetails reward)}}
                    >
                      <div class="card-icon-wrapper">
                        {{icon reward.icon}}
                      </div>
                      <h3 class="card-name">{{reward.name}}</h3>
                      <p class="card-desc">{{reward.description}}</p>
                      
                      <div class="card-footer-info">
                        <span class="rarity-badge rarity-{{reward.rarity}}">
                          {{i18n (concat "itemshop.shop.rarity_" reward.rarity)}}
                        </span>
                        <span class="card-cost">
                          {{icon "award"}} {{fullnumber reward.cost}} Münzen
                        </span>
                      </div>
                    </button>
                  {{/each}}
                </div>

                <!-- Paginierung -->
                {{#if (gt this.totalPages 1)}}
                  <div class="catalog-pagination">
                    {{#each this.pageNumbers as |pageNum|}}
                      <button
                        class="page-num-btn {{if (eq this.currentPage pageNum) 'active'}}"
                        type="button"
                        {{on "click" (fn this.setPage pageNum)}}
                      >
                        {{pageNum}}
                      </button>
                    {{/each}}
                    <button
                      class="page-num-btn"
                      type="button"
                      {{on "click" this.nextPage}}
                      disabled={{eq this.currentPage this.totalPages}}
                    >
                      {{icon "chevron-right"}}
                    </button>
                  </div>
                {{/if}}

              {{else}}
                <div class="empty-shop-state">
                  {{icon "store"}}
                  <p>Keine Items in dieser Kategorie.</p>
                </div>
              {{/if}}
            </div>
          {{/if}}

        </main>

      </div>
    </div>
  </template>
}
