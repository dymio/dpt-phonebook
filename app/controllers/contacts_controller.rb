class ContactsController < ApplicationController
  
  # GET /contacts.tsv
  def index
    #Mime::Type.register "text/tsv", :tsv
    phlines = Contact.get_full_collection

    #respond_to do |format|
    #  format.tsv {
        tsv_text = ""
        phlines.each do |pl|
          tsv_line = rm_tabs pl.name
          pl.phones.each do |plph|
            tsv_line += "\t" + rm_tabs(plph.number)
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
        format.json  { render :json => @contact.prepare_for_json }
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
        format.json  { render :json => @contact.prepare_for_json }
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
    import_counter = { lines_accepted: 0, added_contacts: 0, added_phones: 0, renamed_contacts: 0, removed_contacts: 0, removed_phones: 0 }

    import_file_lines = params[:file].read.split(/[\r\n]+/)
    import_file_lines.each do |ifline|
      line_elements = ifline.split(/[\t]+/)
      next if line_elements.length < 2

      case line_elements[0]
        when '$#-' # remove
          import_remove line_elements[(1..(line_elements.length - 1))], import_counter
        when '$#~' # rename
          import_rename line_elements[(1..(line_elements.length - 1))], import_counter
        when '$#+' # add
          import_add line_elements[(1..(line_elements.length - 1))], import_counter
        else # add
          import_add line_elements, import_counter
      end
    end

    # !!! show report for customer
    # reports = "Import results:\r\n"
    # reports << "Processed " + import_counter[:lines_accepted].to_s + " lines of " + import_file_lines.length.to_s + "\r\n"
    # reports << "Added contacts: " + import_counter[:added_contacts].to_s + "\r\n"
    # reports << "Added phones numbers: " + import_counter[:added_phones].to_s + "\r\n"
    # reports << "Renamed contacts: " + import_counter[:renamed_contacts].to_s + "\r\n"
    # reports << "Removed contacts: " + import_counter[:removed_contacts].to_s + "\r\n"
    # reports << "Removed phones numbers: " + import_counter[:removed_phones].to_s + "\r\n"

    logger.info "Import results:"
    logger.info "Processed " + import_counter[:lines_accepted].to_s + " lines of " + import_file_lines.length.to_s
    logger.info "Added contacts: " + import_counter[:added_contacts].to_s
    logger.info "Added phones numbers: " + import_counter[:added_phones].to_s
    logger.info "Renamed contacts: " + import_counter[:renamed_contacts].to_s
    logger.info "Removed contacts: " + import_counter[:removed_contacts].to_s
    logger.info "Removed phones numbers: " + import_counter[:removed_phones].to_s

    render :text => "OK"
  end

  private

  def import_add selements, import_counter
    work_have_been_done = false
    finded_contacts = Contact.where(name: selements[0])
    if finded_contacts.any?
      our_cont = finded_contacts[0]
      (1..(selements.length - 1)).each do |i|
        if our_cont.phones.where(number: selements[i]).empty?
          our_cont.phones.create number: selements[i]
          import_counter[:added_phones] += 1
          work_have_been_done = true
        end
      end
    else
      new_cont = Contact.create name: selements[0]
      import_counter[:added_contacts] += 1
      (1..(selements.length - 1)).each do |i|
        new_cont.phones.create number: selements[i]
        import_counter[:added_phones] += 1
      end
      work_have_been_done = true
    end
    import_counter[:lines_accepted] += 1 if work_have_been_done
  end

  def import_remove selements, import_counter
    work_have_been_done = false
    finded_contacts = Contact.where(name: selements[0])
    if finded_contacts.any?
      our_cont = finded_contacts[0]
      if selements.length == 1 # only one element => remove contact
        our_cont.destroy
        import_counter[:removed_contacts] += 1
        work_have_been_done = true
      else # several elements => remove phones
        (1..(selements.length - 1)).each do |i|
          our_cont.phones.where(number: selements[i]).each do |deadmans_phone|
            deadmans_phone.destroy
            import_counter[:removed_phones] += 1
            work_have_been_done = true
          end
        end
      end
    end
    import_counter[:lines_accepted] += 1 if work_have_been_done
  end

  def import_rename selements, import_counter
    return false if selements.length < 2
    work_have_been_done = false
    finded_contacts = Contact.where(name: selements[0])
    if finded_contacts.any?
      finded_contacts[0].name = selements[1]
      finded_contacts[0].save
      import_counter[:renamed_contacts] += 1
      work_have_been_done = true
    end
    import_counter[:lines_accepted] += 1 if work_have_been_done
  end

  def rm_tabs chk_string
    chk_string.sub(/[\t]/, ' ')
  end

end
