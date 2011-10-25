class ReservationsController < AuthorizedController
  
  def new
    @dossier = Dossier.find(params[:dossier_id])
    @reservation = Reservation.new(:pickup => DateTime.tomorrow, :dossier => @dossier)
    
    new!
  end
  
  def create
    create! do |success, failure|
      success.html do
        ReservationMailer.user_email(@reservation).deliver
        
        redirect_to dossier_path(@reservation.dossier)
      end
    end
  end
end