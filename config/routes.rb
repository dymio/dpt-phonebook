DptPhonebook::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :contacts, only: [:index, :create, :update, :destroy]
  # !!! match 'popul' => 'phonebook#populaten'

  root :to => 'phonebook#index'
end
