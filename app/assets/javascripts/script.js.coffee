InfoshkaManager = () ->
  tmr = null

  this.show = (inf_message) ->
    $("#infoshka").html('<p>' + inf_message + '</p>')
    $("#infoshka").fadeIn 400
    clearTimeout(tmr) if tmr
    tmr = setTimeout () ->
      $("#infoshka").fadeOut 400
      tmr = null
    ,4800

  this

infoshka_manager = new InfoshkaManager()

# ====================================== #
# ====================================== #

PluploadUploaderInit = () ->
  uploader = new plupload.Uploader
    runtimes : 'gears,html5,flash,silverlight,browserplus'
    browse_button : 'import-file'
    max_file_size : '10mb'
    url : $('#import-file').attr('href') + '?authenticity_token=' + $("head meta[name=csrf-token]").attr('content')
    flash_swf_url : '/assets/js/plupload/plupload.flash.swf'
    silverlight_xap_url : '/assets/js/plupload/plupload.silverlight.xap'
    filters : [ {title : "TSV files", extensions : "tsv"} ]

  uploader.init()

  uploader.bind 'FilesAdded', (up, files) ->
    up.refresh()
    $('#import-file').after '<span>: 0%</span>'
    uploader.start()

  uploader.bind 'UploadProgress', (up, file) ->
    $('#import-file').next().text ': ' + file.percent + '%'

  uploader.bind 'Error', (up, err) ->
    infoshka_manager.show "Error with file upload: " + err.message
    up.refresh() # Reposition Flash/Silverlight

  uploader.bind 'FileUploaded', (up, file) ->
    $('#import-file').next().remove()
    infoshka_manager.show "File sucessfully uploaded"
    setTimeout () ->
      location.reload()
    ,1000

# ====================================== #
# ====================================== #

ContactFormManager = () ->
  self = this
  cntfrm = $("#cntfrm")

  send = () ->
    is_edit = cntfrm.find("input#contact_id").val() != ''
    
    base_url = cntfrm.find("#contact-form").attr 'action'
    base_url += '/' + cntfrm.find("input#contact_id").val() if is_edit
    base_url += '.json'

    ajax_type = 'POST'
    ajax_type = 'PUT' if is_edit

    s_data = 
      authenticity_token: $("head meta[name=csrf-token]").attr('content')
      contact:
        name: cntfrm.find("input#contact_name").val()
        phones_attributes: {}
    cntfrm.find(".numbers li").each (indx) ->
      phone_line = $(this)
      order_ident = phone_line.children('input:first').attr('id').match(/contact_phones_attributes_(.*)_number/)[1]
      s_data.contact.phones_attributes[order_ident] = {}
      s_data.contact.phones_attributes[order_ident].number = phone_line.children('input:first').val()
      if phone_line.children('#contact_phones_attributes_' + order_ident + '_id').length
        s_data.contact.phones_attributes[order_ident].id = phone_line.children('#contact_phones_attributes_' + order_ident + '_id').val()

    $.ajax
      url: base_url
      type: ajax_type
      dataType: 'json'
      data: s_data
      error: (jqXHR, textStatus, errorThrown) ->
      success: (data, textStatus, jqXHR) ->
        # !!! load to list
        #location.reload()
        # ---
        infoshka_manager.show "You sucessfully save contact"
        close()


  set_title = (title_text) ->
    cntfrm.find(".title").text title_text

  get_number_code = (order_ident, phone_id, number_value) ->
    phone_id_text = ''
    phone_id_text = '<input id="contact_phones_attributes_ORDERIDENT_id" name="contact[phones_attributes][ORDERIDENT][id]" type="hidden" value="' + phone_id + '">' if phone_id
    number_value_text = ''
    number_value_text = ' value="' + number_value + '"' if number_value
    code_string = '<li><input id="contact_phones_attributes_ORDERIDENT_number" name="contact[phones_attributes][ORDERIDENT][number]" placeholder="Enter phone number" type="text"' + number_value_text + '>' + phone_id_text + '</li>'
    code_string.replace /ORDERIDENT/g, order_ident.toString()

  clear = () ->
    cntfrm.find("input#contact_id").val ''
    cntfrm.find("input#contact_name").val ''
    cntfrm.find(".numbers").empty()

  load = (line_item) ->
    cntfrm.find("input#contact_id").val line_item.children(".ident").text()
    cntfrm.find("input#contact_name").val line_item.children(".name").text()
    cntf_numbs = cntfrm.find(".numbers")
    cntf_numbs.empty()
    line_item.find(".numbers li").each (indx) ->
      cntf_numbs.append get_number_code(indx, $(this).children(".ident").text(), $(this).children("span").text())

  show = () ->
    $("#overshadow").show()
    cntfrm.show()

  close = () ->
    clear()
    cntfrm.hide()
    $("#overshadow").hide()

  init = () ->
    cntfrm.find(".close").click (evnt) ->
      evnt.preventDefault()
      close()
      false
    cntfrm.find(".addnumber").click (evnt) ->
      evnt.preventDefault()
      cntfrm.find(".numbers").append get_number_code(new Date().getTime())
      false
    cntfrm.find("#contact-form").submit (evnt) ->
      evnt.preventDefault()
      # !!! check (required name, minimum 1 number, required number)
      send()
      false
    # !!! remove phone
    this

  this.openForNew = () ->
    clear()
    set_title "New contact"
    show()

  this.openForEdit = (line_item) ->
    load line_item
    set_title "Edit contact"
    show()

  init()
  this

# ====================================== #
# ------- ON LOAD -------
$(document).ready () ->

  cf_mgr = new ContactFormManager

  # add new contact
  $("#new-contact").click (evnt) ->
    evnt.preventDefault()
    cf_mgr.openForNew()
    false
  $(".phlines .edt_btn").click (evnt) ->
    evnt.preventDefault()
    cf_mgr.openForEdit $(this).closest(".phlines > li")
    false
  $(".phlines .rmv_btn").click (evnt) ->
    evnt.preventDefault()
    line_item = $(this).closest(".phlines > li")
    contact_name = line_item.children(".name").text()
    if confirm('Delete contact "' + contact_name + '". Are you sure?')
      $.ajax
        url: $(this).attr("href")
        type: 'DELETE'
        data:
          authenticity_token: $("head meta[name=csrf-token]").attr('content')
        error: () ->
          infoshka_manager.show "We can't remove " + contact_name + " right now - server return error"
        success: () ->
          infoshka_manager.show "Contact " + contact_name + " removed sucessfully"
          line_item.remove()
    false
  if $('#import-file').length
    new PluploadUploaderInit
  true
