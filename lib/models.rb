require 'sequel'

DB = Sequel.connect('mysql://portfolio_god:password@localhost/hs_portfolio')

#Another way to connect to the database
#DB = Sequel.connect(:adapter=>'mysql', :host=>'localhost', :database=>'hs_portfolio', :user=>'portfolio_god', :password=>'password')

#This makes all Sequel::Model subclasses support many_through_many associations
#Sequel::Model.plugin :many_through_many



#Note: When a model class is created, it parses the schema in the table from the database, and automatically sets up accessor methods for all of the columns in the table. Sequel model classes assume that the table name is an underscored plural of the class name
class Account < Sequel::Model #dataset for DB[:accounts]
    attr_accessor :account_id, :acct_first_name, :acct_last_name, :zipcode, :email, :password, :join_date, :account_hash
    
    one_to_many :students
    one_to_many :activities
    one_to_many :books
    one_to_many :subjects
end

class Activity < Sequel::Model #dataset for DB[:activities]
    attr_accessor :activity_id, :title, :duration, :description, :activity_date, :activity_slug, :account_id
    
    include Comparable
    one_to_many :activities_students
    #many_to_many :subjects, :join_table=>:activities_subjects
    one_to_many :activities_subjects
    many_to_one :account
    
end

#I'm not sure this class is named correctly
class ActivitiesStudent < Sequel::Model #dataset for DB[:activities_students]
    attr_accessor :activities_students_id, :activity_id, :student_id, :account_id
    
    many_to_one :activity
    many_to_one :student
end

class ActivitiesSubject < Sequel::Model #dataset for DB[:activities_subjects]
    attr_accessor :activities_subjects_id, :activity_id, :subject_id, :account_id
    
    many_to_one :activity
    many_to_many :subject
end

class Book < Sequel::Model #dataset for DB[:books]
    attr_accessor :book_id, :title, :author, :rating, :finish_date, :book_slug, :account_id, :fiction, :nonfiction

    include Comparable
    one_to_many :books_students
    one_to_many :books_subjects
    many_to_one :account
    
    def status
        if @fiction
          "Fiction"
        else
          "Nonfiction"
        end
    end
    
end

#I'm not sure this class is named correctly
class BooksStudent < Sequel::Model #dataset for DB[:books_students]
    attr_accessor :books_students_id, :book_id, :student_id, :account_id

    many_to_one :book
    many_to_one :student
end

class BooksSubject < Sequel::Model #dataset for DB[:books_subjects]
    attr_accessor :books_subjects_id, :book_id, :subject_id, :account_id
    
    many_to_one :book
    many_to_one :subject
end

class Student < Sequel::Model #dataset for DB[:students]
    attr_accessor :student_id, :account_id, :stud_first_name, :stud_last_name, :birth_date, :enroll_date, :student_slug

    many_to_one :account
    one_to_many :activities_students
    one_to_many :books_students
end

class Subject < Sequel::Model #dataset for DB[:subjects]
    attr_accessor :subject_id, :subject_name, :subject_slug, :account_id, :description

    many_to_one :account
    many_to_many :activities_subjects
    one_to_many :books_subjects
    
    def create(subject)
        Subject.insert(
          :account_id => subject.account_id,
          :subject_name => subject.subject_name,
          :description => subject.description,
          :subject_slug => subject.subject_slug)
    end
end