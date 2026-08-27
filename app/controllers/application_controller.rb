class ApplicationController < ActionController::Base
  helper_method :current_cart

  # Gives every AppSignal sample a bit of context to filter and group by.
  before_action :tag_appsignal_request

  def current_cart
    @current_cart ||= Cart.new(session)
  end

  private

  def tag_appsignal_request
    return unless defined?(Appsignal)

    Appsignal.add_tags(
      cart_items: current_cart.count,
      demo: request.path.start_with?("/demo")
    )
  end
end
