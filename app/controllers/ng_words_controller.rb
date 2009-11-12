class NgWordsController < ApplicationController
  before_filter :login_as_admin
  layout 'posts'

  @@brand_index = Brand.all(:conditions => "delete_flg is null", 
                            :order => "listed_count DESC", 
                            :limit => 20
                            )
  @@blog_index = Blog.all(:conditions => "delete_flg is null", 
                          :order => "listed_count DESC", 
                          :limit => 20
                          )

  # GET /ng_words
  # GET /ng_words.xml
  def index
    @ng_words = NgWord.paginate(:page => params[:page], 
                                :joins => "INNER JOIN brands on ng_words.brand_id = brands.id", 
                                :order => "brands.name"
                               )

    @brand_index = @@brand_index
    @blog_index = @@blog_index

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ng_words }
    end
  end

  # GET /ng_words/1
  # GET /ng_words/1.xml
  def show
    @ng_word = NgWord.find(params[:id])

    @brand_index = @@brand_index
    @blog_index = @@blog_index

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ng_word }
    end
  end

  # GET /ng_words/new
  # GET /ng_words/new.xml
  def new
    @brand = Brand.find(params[:id])
    @ng_word = NgWord.new
    @ng_word[:brand_id] = @brand.id

    @brand_index = @@brand_index
    @blog_index = @@blog_index
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @ng_word }
    end
  end

  # GET /ng_words/1/edit
  def edit
    @ng_word = NgWord.find(params[:id])
    @brand = Brand.find(@ng_word.brand_id)
    @brand_index = @@brand_index
    @blog_index = @@blog_index
  end

  # POST /ng_words
  # POST /ng_words.xml
  def create
    @ng_word = NgWord.new(params[:ng_word])
    case params[:ng_type]
    when "phonetic"
      @ng_word.ng_type = 0
    when "name"
      @ng_word.ng_type = 1
    end
  
    respond_to do |format|
      if @ng_word.save
        flash[:notice] = 'NgWord was successfully created.'
        format.html { redirect_to(@ng_word) }
        format.xml  { render :xml => @ng_word, :status => :created, :location => @ng_word }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @ng_word.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ng_words/1
  # PUT /ng_words/1.xml
  def update
    @ng_word = NgWord.find(params[:id])

    respond_to do |format|
      if @ng_word.update_attributes(params[:ng_word])
        flash[:notice] = 'NgWord was successfully updated.'
        format.html { redirect_to(@ng_word) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ng_word.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ng_words/1
  # DELETE /ng_words/1.xml
  def destroy
    @ng_word = NgWord.find(params[:id])
    @ng_word.destroy

    respond_to do |format|
      format.html { redirect_to(ng_words_url) }
      format.xml  { head :ok }
    end
  end

  def ng_analyze
    # DestroyNgPosts.destroy_ng_posts
  end
end
