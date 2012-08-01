DptPhonebook::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  match 'contacts/import' => 'contacts#import'
  resources :contacts, only: [:index, :create, :update, :destroy]
  # !!! match 'popul' => 'phonebook#populaten'

  root :to => 'phonebook#index'
end
