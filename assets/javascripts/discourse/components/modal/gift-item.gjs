import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";

export default class GiftItemModal extends Component {
  @tracked recipientUsername = "";

  get reward() {
    return this.args.model.reward;
  }

  get isSubmitDisabled() {
    return !this.recipientUsername || this.recipientUsername.trim().length === 0;
  }

  @action
  submitGift(e) {
    if (e) {
      e.preventDefault();
    }
    if (this.isSubmitDisabled) {
      return;
    }
    this.args.closeModal();
    this.args.model.buyItem(this.reward, this.recipientUsername.trim());
  }

  <template>
    <DModal
      @title={{i18n "itemshop.shop.gift_modal_title" name=this.reward.name}}
      @closeModal={{@closeModal}}
      class="gift-item-modal"
    >
      <:body>
        <form {{on "submit" this.submitGift}} class="gift-item-form form-vertical">
          <div class="control-group">
            <label for="recipient-username-input">{{i18n "itemshop.shop.gift_modal_username_label"}}</label>
            <input
              id="recipient-username-input"
              type="text"
              class="input-large"
              placeholder="Username..."
              required
              {{on "input" (action (mut this.recipientUsername) value="target.value")}}
              value={{this.recipientUsername}}
              autofocus
            />
          </div>
        </form>
      </:body>
      <:footer>
        <DButton
          @action={{this.submitGift}}
          @disabled={{this.isSubmitDisabled}}
          class="btn-primary"
          @icon="gift"
          @label="itemshop.shop.gift_modal_submit"
        />
        <DButton
          @action={{@closeModal}}
          class="btn-default"
          @label="itemshop.cancel"
        />
      </:footer>
    </DModal>
  </template>
}
