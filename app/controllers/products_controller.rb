class ProductsController < ApplicationController
  def index
    # includes(:category, :reviews) is the whole point: without it this page
    # fires one query per product per association. There is a deliberately
    # un-optimised version at /demo/n_plus_one to show the difference.
    @products   = Product.includes(:category, :reviews).order(:name)
    @categories = Category.ordered.includes(:products)
    @featured   = @products.select { |p| p.bestseller? || p.flagship? }.first(4)
  end

  def show
    @product = Product.includes(:category, :reviews).find_by!(slug: params[:slug])
    @related = Product.includes(:category)
                      .where(category_id: @product.category_id)
                      .where.not(id: @product.id)
                      .limit(3)
  rescue ActiveRecord::RecordNotFound
    render_not_found("No product with the slug #{params[:slug].inspect}")
  end

  def category
    @category = Category.find_by!(slug: params[:slug])
    @products = @category.products.includes(:category, :reviews).order(:name)
    render :category
  rescue ActiveRecord::RecordNotFound
    render_not_found("No category with the slug #{params[:slug].inspect}")
  end

  def search
    @query = params[:q].to_s.strip
    @products =
      if @query.empty?
        Product.none
      else
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
        Product.includes(:category, :reviews)
               .where("name LIKE :q OR summary LIKE :q OR description LIKE :q", q: pattern)
               .order(:name)
      end

    Appsignal.add_tags(search_term: @query) if defined?(Appsignal) && @query.present?
  end

  private

  def render_not_found(message)
    @message = message
    render "shared/not_found", status: :not_found
  end
end
