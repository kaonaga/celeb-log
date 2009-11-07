class BlogsController < ApplicationController

  layout 'posts'

  @@brand_index = Brand.all(:conditions => "delete_flg is null", 
                            :order => "listed_count DESC", 
                            :limit => 10
                            )
  @@blog_index = Blog.all(:conditions => "delete_flg is null", 
                          :order => "listed_count DESC", 
                          :limit => 10
                          )

  # GET /blogs
  # GET /blogs.xml
  def index
    @blogs = Blog.paginate(:page => params[:page])
    @brand_index = @@brand_index
    @blog_index = @@blog_index

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blogs }
    end
  end

  # GET /blogs/1
  # GET /blogs/1.xml
  def show
    @blog = Blog.find(params[:id])
    @brand_index = @@brand_index
    @blog_index = @@blog_index
    @posts = Post.paginate(:page => params[:page], 
                           :conditions => ["blog_id = ?", params[:id]]
                           )
    # keyword highlight
    @posts = content_thumbnail_highlight(@posts)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blog }
    end
  end

  # GET /blogs/new
  # GET /blogs/new.xml
  def new
    @blog = Blog.new
    @brand_index = @@brand_index
    @blog_index = @@blog_index

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blog }
    end
  end

  # GET /blogs/1/edit
  def edit
    @blog = Blog.find(params[:id])
    @brand_index = @@brand_index
    @blog_index = @@blog_index
  end

  # POST /blogs
  # POST /blogs.xml
  def create
    @blog = Blog.new(params[:blog])

    respond_to do |format|
      if @blog.save
        flash[:notice] = 'Blog was successfully created.'
        format.html { redirect_to(@blog) }
        format.xml  { render :xml => @blog, :status => :created, :location => @blog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /blogs/1
  # PUT /blogs/1.xml
  def update
    @blog = Blog.find(params[:id])

    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        flash[:notice] = 'Blog was successfully updated.'
        format.html { redirect_to(@blog) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1
  # DELETE /blogs/1.xml
  def destroy
    @blog = Blog.find(params[:id])
    # @blog.destroy
    @blog.delete_flg = 1
    @blog.save

    respond_to do |format|
      format.html { redirect_to(blogs_url) }
      format.xml  { head :ok }
    end
  end
end
