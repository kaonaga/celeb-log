class BrandsController < ApplicationController
  # before_filter :login_required , :except => [:index, :show]
  before_filter :login_as_admin , :except => [:index, :show]
  layout 'posts'

  @@brand_index = Brand.all(:conditions => "delete_flg is null", 
                            :order => "listed_count DESC", 
                            :limit => 20
                            )
  @@blog_index = Blog.all(:conditions => "delete_flg is null", 
                          :order => "listed_count DESC", 
                          :limit => 20
                          )

  @@main_title = "芸能人のブログで話題のブランドをさがすならセレブログ"
  @@main_keyword = ["芸能人", "ブログ"]
  @@main_description = @@main_title + "です。"

  # GET /brands
  # GET /brands.xml
  def index
    @session = session
    @brands = Brand.paginate(:page => params[:page], 
                             :conditions => "listed_count > 0 and delete_flg is null"
                            )
    @brand_index = @@brand_index
    @blog_index = @@blog_index

    @title = "芸能人がブログで紹介しているブランドがわかる | " + @@main_title
    @meta_keywords = @@main_keyword[0] + "," + @@main_keyword[1]
    @meta_description = @@main_keyword[0] + " " + @@main_keyword[1]+ "。" + @@main_description

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @brands }
    end
  end

  # GET /brands/1
  # GET /brands/1.xml
  def show
    @session = session
    @brand = Brand.find(params[:id])
    @brand_index = @@brand_index
    @blog_index = @@blog_index
    @posts = Post.paginate(:page => params[:page], 
                           :conditions => ["brand_id = ? and delete_flg is null", params[:id]], 
                           :order => "created_at DESC"
                           )
    # keyword highlight
    @posts = content_tweet_highlight(@posts)

    @title = "#{@brand.name} 芸能人のブログで紹介されている#{@brand.name} | " + @@main_title
    @meta_keywords = @@main_keyword[0] + "," + @@main_keyword[1] + "," + @brand.name
    @meta_description = "#{@@main_keyword[0]} #{@brand.name}。 芸能人のブログで紹介されている#{@brand.name}です。"

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @brand }
    end
  end

  # GET /brands/new
  # GET /brands/new.xml
  def new
    @brand = Brand.new
    @brand_index = @@brand_index
    @blog_index = @@blog_index

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @brand }
    end
  end

  # GET /brands/1/edit
  def edit
    @brand = Brand.find(params[:id])
    @brand_index = @@brand_index
    @blog_index = @@blog_index
  end

  # POST /brands
  # POST /brands.xml
  def create
    @brand = Brand.new(params[:brand])

    respond_to do |format|
      if @brand.save
        flash[:notice] = 'Brand was successfully created.'
        format.html { redirect_to(@brand) }
        format.xml  { render :xml => @brand, :status => :created, :location => @brand }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @brand.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /brands/1
  # PUT /brands/1.xml
  def update
    @brand = Brand.find(params[:id])

    respond_to do |format|
      if @brand.update_attributes(params[:brand])
        flash[:notice] = 'Brand was successfully updated.'
        format.html { redirect_to(@brand) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @brand.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /brands/1
  # DELETE /brands/1.xml
  def destroy
    @brand = Brand.find(params[:id])
    # @brand.destroy
    @brand.delete_flg = 1
    @brand.save

    respond_to do |format|
      format.html { redirect_to(brands_url) }
      format.xml  { head :ok }
    end
  end
end
