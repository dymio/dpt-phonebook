DptPhonebook::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :phones, only: :destroy

  match 'contacts/import' => 'contacts#import'
  resources :contacts, only: [:index, :create, :update, :destroy]

  root :to => 'phonebook#index'
end
