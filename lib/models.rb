require 'sequel'

DB = Sequel.connect('mysql://portfolio_god:password@localhost/hs_portfolio')

#Another way to connect to the database
#DB = Sequel.connect(:adapter=>'mysql', :host=>'localhost', :database=>'hs_portfolio', :user=>'portfolio_god', :password=>'password')

#Note: When a model class is created, it parses the schema in the table from the database, and automatically sets up accessor methods for all of the columns in the table. Sequel model classes assume that the table name is an underscored plural of the class name.


class Account < Sequel::Model #dataset for DB[:accounts]
    #Associations
    one_to_many :students
    one_to_many :activities
    one_to_many :activities_students
    one_to_many :activities_subjects
    one_to_many :books
    one_to_many :books_students
    one_to_many :books_subjects
    one_to_many :subjects
    
    #Dataset functions
    dataset_module do
        order :by_first_name, :acct_first_name
    end
end

class Activity < Sequel::Model #dataset for DB[:activities]
    #Associations
    one_to_many :activities_students
    one_to_many :activities_subjects
    many_to_one :account
    
    #Dataset functions
    dataset_module do
        order :by_date, :activity_date
        limit :five, 5
    end
end

class ActivitiesStudent < Sequel::Model #dataset for DB[:activities_students]
    #Associations
    many_to_one :account
    many_to_one :activity
end

class ActivitiesSubject < Sequel::Model #dataset for DB[:activities_subjects]
    #Associations
    many_to_one :account
    many_to_one :activity
end

class Book < Sequel::Model #dataset for DB[:books]
    #Associations
    one_to_many :books_students
    one_to_many :books_subjects
    many_to_one :account
    
    #Dataset functions
    dataset_module do
        order :by_date, :finish_date
        limit :five, 5
    end
    
end

class BooksStudent < Sequel::Model #dataset for DB[:books_students]
    #Associations
    many_to_one :account
    many_to_one :book
end

class BooksSubject < Sequel::Model #dataset for DB[:books_subjects]
    #Associations
    many_to_one :account
    many_to_one :book
end

class Student < Sequel::Model #dataset for DB[:students]
    #Associations
    many_to_one :account
    one_to_many :activities_students
    one_to_many :books_students
    
    #Dataset functions
    dataset_module do
        order :by_birth, :birth_date
    end
end

class Subject < Sequel::Model #dataset for DB[:subjects]
    #Associations
    many_to_one :account
    one_to_many :activities_subjects
    one_to_many :books_subjects
    
    #Dataset functions
    dataset_module do
        order :by_name, :subject_name
    end
end

class String
  def initial
    self[0,1]
  end
end