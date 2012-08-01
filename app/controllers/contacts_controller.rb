class ContactsController < ApplicationController
  
  # GET /contacts.tsv
  def index
    #Mime::Type.register "text/tsv", :tsv
    phlines = Contact.get_full_collection

    #respond_to do |format|
    #  format.tsv {
        tsv_text = ""
        phlines.each do |pl|
          tsv_line = rm_tabs pl[:name]
          pl[:phones].each do |plph|
            tsv_line += "\t" + rm_tabs(plph[:number])
          end
          tsv_text += tsv_line + "\r\n"
        end
        render :text => tsv_text
    #  }
    #  format.html { redirect_to(root_url) }
    #end
  end

  def create
    @contact = Contact.new(params[:contact])
   
    respond_to do |format|
      if @contact.save
        format.html  { redirect_to(root_url,
                      :notice => 'Contact was successfully created.') }
        format.json  { head :no_content }
      else
        format.html  { redirect_to(root_url,
                      :notice => 'Error with contact creation.') }
        format.json  { render :json => @contact.errors,
                      :status => :unprocessable_entity }
      end
    end
  end

  def update
    @contact = Contact.find(params[:id])
   
    respond_to do |format|
      if @contact.update_attributes(params[:contact])
        format.html  { redirect_to(root_url,
                      :notice => 'Contact was successfully updated.') }
        format.json  { head :no_content }
      else
        format.html  { redirect_to(root_url,
                      :notice => 'Error with contact updating.') }
        format.json  { render :json => @contact.errors,
                      :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy
   
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

  def import
    params[:file].read.split(/[\r\n]{1,2}/).each do |lfline|
      logger.info "MOTHERFUCKER FILE LINE" + lfline
    end
    render :text => "OK"
  end

  private

  def rm_tabs chk_string
    chk_string.sub(/[\t]/, ' ')
  end

end
