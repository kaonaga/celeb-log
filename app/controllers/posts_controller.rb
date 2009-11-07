class PostsController < ApplicationController

  @@brand_index = Brand.all(:conditions => "delete_flg is null", 
                            :order => "listed_count DESC", 
                            :limit => 10
                            )
  @@blog_index = Blog.all(:conditions => "delete_flg is null", 
                          :order => "listed_count DESC", 
                          :limit => 10
                          )

  # GET /posts
  # GET /posts.xml
  def index
    # @posts = Post.all
    @posts = Post.paginate( :page => params[:page], 
                            :conditions => "delete_flg is NULL", 
                            :order => "posted_date DESC"
                          )
    # keyword highlight
    @posts = content_thumbnail_highlight(@posts)

    @brand_index = @@brand_index
    @blog_index = @@blog_index

    # @posts = Post.paginate_by_board_id @board.id, :page => params[:page], :order => 'updated_at DESC'
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.find(params[:id])
    # keyword highlight
    @post = content_highlight(@post)

    @brand_index = @@brand_index
    @blog_index = @@blog_index

    brand_name = @post.brand.name
    brand_category = @post.brand.category
    begin
      @amazon_recommendations = AmazonAwsSearch.item_search(brand_category, {'Brand' => brand_name})
      # @amazon_recommendations = AmazonAwsSearch.keyword_search("#{brand_name}")
    rescue => e
      @amazon_error = e
    end

    begin
      @rakuten_recommendations = RakutenSearch.item_search(brand_category, brand_name)
    rescue  => e
      @rakuten_error = e
    end
    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new
    @brand_index = @@brand_index
    @blog_index = @@blog_index
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    @brand_index = @@brand_index
    @blog_index = @@blog_index
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = Post.new(params[:post])

    respond_to do |format|
      if @post.save
        flash[:notice] = 'Post was successfully created.'
        format.html { redirect_to(@post) }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = Post.find(params[:id])

    respond_to do |format|
      if @post.update_attributes(params[:post])
        flash[:notice] = 'Post was successfully updated.'
        format.html { redirect_to(@post) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = Post.find(params[:id])
    # @post.destroy
    @post.delete_flg = 1
    @post.save

    respond_to do |format|
      format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
    end
  end
end
