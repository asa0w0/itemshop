import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { concat } from "@ember/helper";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import fullnumber from "../../helpers/fullnumber";

export default class ItemDetailModal extends Component {
  @service router;

  get reward() {
    return this.args.model.reward;
  }

  get isBalanceLessThanCost() {
    return this.args.model.balance < this.reward.cost;
  }

  @action
  buy() {
    this.args.closeModal();
    this.args.model.buyItem(this.reward);
  }

  @action
  gift() {
    this.args.closeModal();
    this.args.model.giftItem(this.reward);
  }

  <template>
    <DModal
      @title={{this.reward.name}}
      @closeModal={{@closeModal}}
      class="item-detail-modal"
    >
      <:body>
        <div class="item-detail-container">
          <div class="item-detail-header">
            <div class="item-detail-icon-wrapper rarity-{{this.reward.rarity}}">
              {{icon this.reward.icon}}
            </div>
            <div class="item-detail-meta">
              <h2 class="item-name">{{this.reward.name}}</h2>
              <div class="item-badges">
                <span class="rarity-badge rarity-{{this.reward.rarity}}">
                  {{i18n (concat "itemshop.shop.rarity_" this.reward.rarity)}}
                </span>
                <span class="type-badge">{{this.reward.reward_type}}</span>
              </div>
            </div>
          </div>

          <div class="item-detail-description">
            <p>{{this.reward.description}}</p>
          </div>

          <table class="item-detail-specs">
            <tbody>
              <tr>
                <th>Preis</th>
                <td>{{icon "award"}} {{fullnumber this.reward.cost}} Münzen</td>
              </tr>
              <tr>
                <th>Anzahl</th>
                <td>unbegrenzt</td>
              </tr>
              <tr>
                <th>Kategorie</th>
                <td>{{this.reward.category}}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </:body>
      <:footer>
        <DButton
          @action={{this.buy}}
          @disabled={{this.isBalanceLessThanCost}}
          class="btn-primary buy-button"
          @icon="cart-shopping"
          @label="itemshop.shop.redeem"
        />
        <DButton
          @action={{this.gift}}
          @disabled={{this.isBalanceLessThanCost}}
          class="btn-default gift-button"
          @icon="gift"
          @label="itemshop.shop.gift"
        />
        <DButton
          @action={{@closeModal}}
          class="btn-default"
          @label="itemshop.close"
        />
      </:footer>
    </DModal>
  </template>
}
