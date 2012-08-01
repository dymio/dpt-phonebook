class PhonesController < ApplicationController
  
  def destroy
    @phone = Phone.find(params[:id])
    @phone.destroy
   
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

end
