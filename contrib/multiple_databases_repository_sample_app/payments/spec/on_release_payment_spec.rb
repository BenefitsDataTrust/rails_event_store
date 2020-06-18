require_relative 'spec_helper'

module Payments
  RSpec.describe OnReleasePayment do
    it 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      Payments.arrange(stream, [PaymentAuthorized.new(data: {transaction_id: transaction_id, order_id: order_id})])
      Payments.act(ReleasePayment.new(transaction_id: transaction_id, order_id: order_id))

      expect(Payments.event_store).to have_published(
        an_event(PaymentReleased)
          .with_data(transaction_id: transaction_id, order_id: order_id)
      )
    end
  end
end