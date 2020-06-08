require_relative 'spec_helper'

module Orders
  RSpec.describe RemoveItemFromBasket do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{aggregate_id}" }
    let(:customer_id) { 997 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'item is removed from draft order' do
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id})])
      act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      expect(Orders.event_store).to have_published(
        an_event(ItemRemovedFromBasket)
          .with_data(order_id: aggregate_id, product_id: product_id)
      )
    end

    it 'no remove allowed to created order' do
      arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: order_number, customer_id: customer_id})])

      expect do
        act(RemoveItemFromBasket.new(order_id: aggregate_id, product_id: product_id))
      end.to raise_error(Order::AlreadySubmitted)
    end
  end
end
