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

# security questions
strip = (html) ->
  tmp = document.createElement "DIV"
  tmp.innerHTML = html
  answer = tmp.textContent||tmp.innerText
  $(tmp).remove()
  answer

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
    ,1200

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
        infoshka_manager.show "You sucessfully save contact \"" + strip(s_data.contact.name) + "\""
        if is_edit
          line_item = $("#contact_" + data.id)
          line_item.children(".name").text(data.name)
          numbers_list = line_item.find(".numbers")
          numbers_list.empty()
          $.each data.phones, (indx, val) ->
            numbers_list.append('<li><p class="ident">' + val.id + '</p><span>' + val.number + '</span></li>')
        else
          location.reload()
        close()

  set_title = (title_text) ->
    cntfrm.find(".title").text title_text

  get_number_code = (order_ident, phone_id, number_value) ->
    phone_id_text = ''
    phone_id_text = '<input id="contact_phones_attributes_ORDERIDENT_id" name="contact[phones_attributes][ORDERIDENT][id]" type="hidden" value="' + phone_id + '">' if phone_id
    number_value_text = ''
    number_value_text = ' value="' + number_value + '"' if number_value
    code_string = '<li><input id="contact_phones_attributes_ORDERIDENT_number" name="contact[phones_attributes][ORDERIDENT][number]" placeholder="Enter phone number" type="text"' + number_value_text + '><a class="rem_phone" href="#" title="Remove phone number"></a>' + phone_id_text + '</li>'
    code_string.replace /ORDERIDENT/g, order_ident.toString()

  get_number_id = (number_line) ->
    answer = null
    id_input_id = number_line.children("input:first").attr('id').replace(/\_number/, '_id')
    if number_line.children("#" + id_input_id).length > 0
      answer = number_line.children("#" + id_input_id).val()
    answer

  set_number_remove_action = (jqblock) ->
    jqblock.find(".rem_phone").click (evnt) ->
      evnt.preventDefault()
      number_block = $(this).parent()
      this_number_id = get_number_id number_block
      if this_number_id

        exists_numbers_count = 0
        cntfrm.find(".numbers li").each (indx) ->
          exists_numbers_count += 1 if get_number_id($(this)) != null

        if exists_numbers_count < 2
          infoshka_manager.show "Sorry, you can't remove last exist phone number"
          return false

        if confirm('Delete phone number?')
          $.ajax
            url: 'phones/' + this_number_id
            type: 'DELETE'
            data:
              authenticity_token: $("head meta[name=csrf-token]").attr('content')
            error: (jqXHR, textStatus, errorThrown) ->
              infoshka_manager.show "We can't remove phone number right now - server return error"
            success: (data, textStatus, jqXHR) ->
              infoshka_manager.show "Number has been removed sucessfully"
              number_block.remove()
              # update list element
              list_elem = $("#contact_" + cntfrm.find("input#contact_id").val())
              list_elem.find(".numbers .ident").each (indx) ->
                $(this).parent().remove() if $(this).text() == this_number_id
              

      else
        number_block.remove()
      false

  check = () ->
    error_msg = ""
    error_msg += "<br /> - Empty contact name field" if cntfrm.find("input#contact_name").val() == ""
    if cntfrm.find(".numbers li").length < 1
      error_msg += "<br /> - Contact can't exist without phone numbers"
    else
      numbers_miss = 0
      cntfrm.find(".numbers li").each (indx) ->
        numbers_miss += 1 if $(this).children("input:first").val() == ""
      error_msg += "<br /> - Have " + numbers_miss + " empty phones numbers fields" if numbers_miss > 0
    error_msg = "Have some errors in contact form:" + error_msg if error_msg != ""
    infoshka_manager.show error_msg
    error_msg == ""

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
    set_number_remove_action cntf_numbs

  show = () ->
    $("#overshadow").show()
    cntfrm.show()
    cntfrm.find("input#contact_name").focus()

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
      set_number_remove_action cntfrm.find(".numbers li:last")
      cntfrm.find(".numbers li:last input:first").focus()
      false
    cntfrm.find("#contact-form").submit (evnt) ->
      evnt.preventDefault()
      if check()
        send()
      false
    
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

  $("#content .phlines > li").click (evnt) ->
    $(this).toggleClass 'active'

  # edit contact
  $(".phlines .edt_btn").click (evnt) ->
    evnt.preventDefault()
    cf_mgr.openForEdit $(this).closest(".phlines > li")
    false

  # remove contact
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
          infoshka_manager.show "We can't remove " + strip(contact_name) + " right now - server return error"
        success: () ->
          infoshka_manager.show "Contact " + strip(contact_name) + " removed sucessfully"
          prev_item = line_item.prev()
          line_item.remove()
          if prev_item.hasClass 'letter'
            prev_item.remove() if (prev_item.next().length == 0) || (prev_item.next().hasClass('letter'))

    false
  if $('#import-file').length
    new PluploadUploaderInit
  true
