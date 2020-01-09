class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :destroy, :edit, :update, :update_status]
  
  def index
    @items = Item.limit(10)
    
  end
  
  def new
    @item = Item.new
    set_selections(@item)
  end

  def create
    @item = Item.new(item_params)
    @item.status = "出品中"
    if @item.valid? && item_images[:item_images] != nil && item_images[:item_images].length <= 10
      @item.save
      item_images[:item_images].each do |image|
        @item_image = ItemImage.create(image: image, item_id: @item.id)
      end
      redirect_to item_path @item
    else
      set_selections(@item)
      render :new
    end
  end

  def show
    @seller_items = Item.where.not(id: @item.id).where(seller_id: @item.seller_id).order(updated_at: :desc).limit(6)
    @category_items = Item.where.not(id: @item.id).where(category_id: @item.category_id).order(updated_at: :desc).limit(6)
  end

  def category
    @category = Category.find(params[:id])
    @categorys = @category.children
    respond_to do |format|
      format.json
    end
  end

  def destroy
    if current_user.id == @item.seller_id && @item.destroy
      redirect_to user_path(current_user)
    else
      redirect_to item_path @item
    end
  end

  def edit
    set_selections(@item)
  end

  def update
    if @item.update(item_params) && ( @item.item_images.length != 0 || item_images[:item_images] != nil ) && @item.item_images.length + item_images[:item_images].length <= 10
      if item_images[:item_images] != nil
        item_images[:item_images].each do |image|
          @item_image = ItemImage.create(image: image, item_id: @item.id)
        end
      end
      redirect_to item_path @item
    else
      set_selections(@item)
      render :edit
    end
  end

  def update_status
    if @item.status == "出品中"
      @item.status = "公開停止中"
    else @item.status == "公開停止中"
      @item.status = "出品中"
    end
    if @item.save
      redirect_to item_path @item
    else
      render :show
    end
  end

  def destroy_image
    @image = ItemImage.find(params[:id])
    @item = Item.find(@image.item_id)
    @image.destroy if current_user.id == @item.seller_id
    set_selections(@item)
    render :edit
  end


  private
  def item_params
    params.require(:item).permit(:name, :comment, :category_id, :condition, :brand, :size, :price, :arrival_date, :charge, :location, :delivery).merge(seller_id: current_user.id)
  end

  def item_images
    params.require(:item).permit({item_images: []})
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def set_selections(item)
    @small_categorys = item.category.siblings if item.category.present?
    @middle_categorys = item.category.parent.siblings if item.category.present?
    @categorys = Category.where(ancestry: nil)
    @prefectures = Prefecture.all
  end

end
