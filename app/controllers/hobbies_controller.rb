class HobbiesController < ApplicationController
  before_action :set_hobby, only: [:show, :edit, :destroy, :update]

  def index
    @hobbies = policy_scope(Hobby).order(created_at: :desc)
    @hobbies = Hobby.where.not(latitude: nil, longitude: nil)

    if params[:title]
      @hobbies = @hobbies.where("title ILIKE ?", "%#{params[:title]}%").order("created_at DESC")
    end

    if params[:city]
      @hobbies = @hobbies.where("address ILIKE ?", "%#{params[:city]}%")
    end

    if params[:category]
      # @categories = @categories.where("name ILIKE ?", "%#{params[:category]}%")
      @hobbies = @hobbies.joins(hobby_categories: [:category]).where('categories.name ILIKE ?', "%#{params[:category]}%")
    end


    @hash = Gmaps4rails.build_markers(@hobbies) do |hobby, marker|
      marker.lat hobby.latitude
      marker.lng hobby.longitude
      # marker.infowindow render_to_string(partial: "/flats/map_box", locals: { flat: flat })
    end
  end

  def show
    authorize @hobby
    @events = @hobby.events
    @hobby = Hobby.find(params[:id])

    @hash = Gmaps4rails.build_markers(@hobby) do |hobby, marker|
      marker.lat hobby.latitude
      marker.lng hobby.longitude
      # marker.infowindow render_to_string(partial: "/flats/map_box", locals: { flat: flat })
    end
  end

  def new
    @hobby = Hobby.new
    @categories = Category.all
    authorize @hobby
  end

  def create
    @hobby = Hobby.new(hobby_params)
    authorize @hobby
    @hobby.user_id = current_user[:id]
    @hobby.review_count = @hobby.average_score = @hobby.likes = 0
    @hobby.deleted = @hobby.hidden = false


    if @hobby.save
      params[:hobby][:categories][1..-1].each { |category_id| HobbyCategory.create(category_id: category_id, hobby_id: @hobby.id) }
      redirect_to hobby_path(@hobby)
    else
      render :new
    end
  end

  def edit
    authorize @hobby
  end

  def update
    authorize @hobby

    if @hobby.update(hobby_params)
      redirect_to hobby_path(@hobby)
    else
      render :new
    end
  end

  def destroy
    authorize @hobby
    @hobby.deleted = @hobby.hidden = true
    @hobby.save

    redirect_to root_path
  end


  private

  def set_hobby
    @hobby = Hobby.find(params[:id])
  end

  def hobby_params
    params.require('hobby').permit(:title, :description, :summary, :address, photos: [])
  end
end
