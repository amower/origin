require 'sinatra' #load the gem
require 'models_v2' #load the ruby file
require 'erb'
#require 'sequel' #load sequel
require 'time' #load gem?

#require 'string_helpers' #load gem (allows use of .slug!)

#Connect to the database
#DB = Sequel.connect('mysql://portfolio_god:password@localhost/hs_portfolio')

#subjects = ['Foreign Language', 'Health & Fitness', 'Home Economics', 'Language Arts', 'Mathematics', 'Performing & Visual Arts', 'Social Studies', 'Science', 'Technology']
#Sequel::Model.plugin :many_through_many

#Dataset Creators
#accounts = DB[:accounts]
#activities = DB[:activities]
#activities_students = DB[:activities_students]
#activities_subjects = DB[:activities_subjects].inner_join(:subjects, :subject_id => :subject_id)
#books = DB[:books]
#books_students = DB[:books_students]
#books_subjects = DB[:books_subjects]
#students = DB[:students]
#subjects = DB[:subjects]

################################################################# THE REAL DEAL
#Homepage currently with just a list of account holders
get('/home/') do
   @accounts = Account.order(:acct_first_name)
   erb :home
end

#Form to create a new account
get('/accounts/new') do
   erb :new_account
end

#Post new_account form data into accounts table & insert basic subjects
post('/accounts/create') do
   #Insert new_account form values into accounts table as new object
   Account.insert(
      :acct_first_name => params[:acct_first_name],
      :acct_last_name => params[:acct_last_name],
      :zipcode => params[:zipcode],
      :email => params[:email],
      :password => params[:password],
      :join_date => params[:join_date],
      :account_hash => params[:acct_last_name].downcase)
   
   #Snag newly-created auto-incremented account_id   
   last_insert_id = Account.max(:account_id)
   
   #Set static subjects to a variable
   static_subjects = ['Foreign Language', 'Health & Fitness', 'Home Economics', 'Language Arts', 'Mathematics', 'Performing & Visual Arts', 'Science', 'Social Studies', 'Technology']
   
   #Insert basic subjects automatically when new account is created
   static_subjects.each do |name|
      Subject.insert(
         :account_id => last_insert_id,
         :subject_name => name,
         :subject_slug => name.downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   end
   
   #Go immediately to account info page   
   redirect "/accounts/#{last_insert_id}"
end

#Personal account information page
get('/accounts/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).order(:birth_date)
   
   erb :account_info
end

get('/accounts/update/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   
   erb :update_account
end

#Update an existing account
post('/accounts/create/:acct_id') do
   i = params['acct_id'].to_i
   
   Account.where(:account_id => i).update(
      :acct_first_name => params[:acct_first_name],
      :acct_last_name => params[:acct_last_name],
      :zipcode => params[:zipcode],
      :email => params[:email],
      :password => params[:password],
      :account_hash => params[:acct_last_name].downcase)
   
   redirect "/accounts/#{i}"
end

get('/accounts/change/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   
   erb :delete_account
end

post('/accounts/delete/:acct_id') do
   i = params['acct_id'].to_i
   
   ActivitiesStudent.where(:account_id => i).delete
   ActivitiesSubject.where(:account_id => i).delete
   Activity.where(:account_id => i).delete
   BooksStudent.where(:account_id => i).delete
   BooksSubject.where(:account_id => i).delete
   Book.where(:account_id => i).delete
   Subject.where(:account_id => i).delete
   Student.where(:account_id => i).delete
   Account.where(:account_id => i).delete
   
   redirect "/home/"
end

#Personal Account Dashboard
get('/dashboard/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @activities = Activity.where(account_id: i).reverse_order(:activity_date).limit(10)
   @activity_subjects = ActivitiesSubject.join(:subjects, :subject_id => :subject_id)
   @subjects = Subject.where(account_id: i).order(:subject_name)
   @books = Book.where(account_id: i).reverse_order(:finish_date).limit(10)
   @students = Student.where(account_id: i).order(:birth_date)
   
   erb :dashboard
end

#################################################################### ACTIVITIES
#List of all activities for a given account
get('/activities/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @activities = Activity.where(account_id: acct_id).reverse_order(:activity_date)
   @subjects = Subject.where(account_id: acct_id).order(:subject_name)
   
   erb :show_activities
end

#Form for submittig a new activity in a given account
get('/activities/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).reverse_order(:birth_date)
   @subjects = Subject.where(account_id: i).order(:subject_name)
  
   erb :new_activity
end

#Insert rows from the 'new activity' form into the database
post('/activities/create/:acct_id') do
   #Define variables from form input
   i = params['acct_id'].to_i
   
   #Insert said data into the database
   Activity.insert(
      :account_id => i,
      :activity_date => params[:activity_date], 
      :title => params[:title],
      :duration => params[:duration],
      :description => params[:description],
      :activity_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
    
   #Grab the newly-created auto-incremented activity_id on this account   
   last_insert_id = Activity.where(account_id: i).max(:activity_id)
    
   #Insert meta data into the activities_students table
   params[:student_id].each do |id|
      ActivitiesStudent.insert(
         :activity_id => last_insert_id,
         :student_id => id,
         :account_id => i) 
   end
    
   #Insert meta data into the activities_subjects table
   params[:subject_id].each do |id|
      ActivitiesSubject.insert(
         :activity_id => last_insert_id,
         :subject_id => id,
         :account_id => i)
   end
   
   redirect "/activities/#{i}"
end

#Form to update a particular activity prepopulated with current info
get('/activities/update/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   act_id = params['act_id'].to_i
   
   @activity = Activity.where(activity_id: act_id)
   @students = Student.where(account_id: i)
   @subjects = Subject.where(account_id: i)
   
   erb :update_activity
end

#Update input in the db
post('/activities/create/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   act_id = params['act_id'].to_i
   
   #Insert said data into the database
   Activity.where(activity_id: act_id).update(
      :activity_date => params[:activity_date], 
      :title => params[:title],
      :duration => params[:duration],
      :description => params[:description],
      :activity_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
    
   ActivitiesStudent.where(activity_id: act_id).delete
   ActivitiesSubject.where(activity_id: act_id).delete
   
   #Insert updated meta data into the activities_students table
   params[:student_id].each do |id|
      ActivitiesStudent.insert(
         :activity_id => act_id,
         :student_id => id,
         :account_id => i) 
   end
    
   #Insert updated meta data into the activities_subjects table
   params[:subject_id].each do |id|
      ActivitiesSubject.insert(
         :activity_id => act_id,
         :subject_id => id,
         :account_id => i)
   end
   
   redirect "/activities/#{i}/#{act_id}"
end

#Retrieve the form to delete an activity
get('/activities/change/:act_id') do
   act_id = params['act_id'].to_i
   
   @activity = Activity.where(activity_id: act_id)
   
   erb :delete_activity
end

post('/activities/delete/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   act_id = params['act_id'].to_i
   
   ActivitiesStudent.where(activity_id: act_id).delete
   ActivitiesSubject.where(activity_id: act_id).delete
   Activity.where(activity_id: act_id).delete
   
   redirect "/dashboard/#{i}"
end

################################################################################################################################################################################################################################# BOOKS
#Display list of books for a given account
get('/books/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @books = Book.where(account_id: acct_id).order(Sequel.desc(:finish_date), :title)
   
   erb :show_books
end

#Form to submit new book in a given account
get('/books/new/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @students = Student.where(account_id: acct_id).reverse_order(:birth_date)
   @subjects = Subject.where(account_id: acct_id).order(:subject_name)
   
   erb :new_book
end

#Insert new book into 'books' table in the database
post('/books/create/:acct_id') do
   #Assign variables
   account_id = params['acct_id'].to_i
   title = params[:title]
   author = params[:author]
   fiction = params[:fiction]
   nonfiction = params[:nonfiction]
   rating = params[:rating]
   finish_date = params[:finish_date]
   #finish_date = Time.parse(params[:finish_date])
   book_slug = params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, '')
   
   #Query for db insertion
   Book.insert(
      :account_id => account_id,
      :title => title, 
      :author => author,
      :fiction => fiction,
      :nonfiction => nonfiction,
      :rating => rating, 
      :finish_date => finish_date,
      :book_slug => book_slug)
   
   #Assign variable to the newly-created, auto-incremented book_id   
   last_insert_id = Book.max(:book_id)
   
   #Use the newly-created book instance to populate the related books_students table
   params[:student_id].each do |id|
      BooksStudent.insert(
         :book_id => last_insert_id,
         :student_id => id,
         :account_id => account_id) 
   end
   
   #Use the newly-created book instance to populate the related books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => last_insert_id,
         :subject_id => id,
         :account_id => account_id)
   end
   
   redirect "/dashboard/#{account_id}"
end

#Form to update a particular book prepopulated with current info
get('/books/update/:acct_id/:book_id') do
   account_id = params['acct_id'].to_i
   book_id = params['book_id'].to_i
   
   @book = Book.where(book_id: book_id)
   @students = Student.where(account_id: account_id)
   @subjects = Subject.where(account_id: account_id)
   
   erb :update_book
end

#Submit updated input into the db
post('/books/create/:acct_id/:book_id') do
   acct_id = params['acct_id'].to_i
   book_id = params['book_id'].to_i
   
   finish_date = params[:finish_date]
   title = params[:title]
   author = params[:author]
   rating = params[:rating]
   fiction = params[:fiction]
   nonfiction = params[:nonfiction]
   book_slug = params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, '')
   
   #Insert said data into the database
   Book.where(book_id: book_id).update(
      :finish_date => finish_date, 
      :title => title,
      :author => author,
      :rating => rating,
      :fiction => fiction,
      :nonfiction => nonfiction,
      :book_slug => book_slug)
   
   #Clear meta students & subjects rows related to current book entirely so they can be deleted or added to based on new selections 
   BooksStudent.where(book_id: book_id).delete
   BooksSubject.where(book_id: book_id).delete
   
   #Insert updated meta data into the books_students table
   params[:student_id].each do |id|
      BooksStudent.insert(
         :book_id => book_id,
         :student_id => id,
         :account_id => acct_id) 
   end
    
   #Insert updated meta data into the books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => book_id,
         :subject_id => id,
         :account_id => acct_id)
   end
   
   redirect "/dashboard/#{acct_id}"
end

get('/books/change/:book_id') do
   book_id = params['book_id'].to_i
   
   @book = Book.where(book_id: book_id)
   
   erb :delete_book
end

post('/books/delete/:acct_id/:book_id') do
   account_id = params['acct_id'].to_i
   book_id = params['book_id'].to_i
   
   BooksStudent.where(book_id: book_id).delete
   BooksSubject.where(book_id: book_id).delete
   Book.where(book_id: book_id).delete
   
   redirect "/dashboard/#{account_id}"
end

get('/books/author/:acct_id/:author') do
   account_id = params['acct_id'].to_i
   author = params['author']
   
   @books = Book.where(account_id: account_id).where(Sequel.like(:author, "#{author}%"))
   
   erb :show_author
end

get('/books/author/:acct_id/:stud_id/:author') do
   account_id = params['acct_id'].to_i
   student_id = params['stud_id'].to_i
   author = params['author']
   
   @books = BooksStudent.join(:books, :book_id => :book_id).where(Sequel[:books_students][:account_id] => account_id).where(Sequel[:books_students][:student_id] => student_id).where(Sequel.like(:author, "#{author}%"))
   
   erb :student_author
end

###################################################################### SUBJECTS
#Page that displays list of subjects with all related activities
get('/subjects/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: acct_id)
   @subjects = Subject.where(account_id: acct_id).order(:subject_name)
   @activities = Activity.join(:activities_subjects, :activity_id => :activity_id).join(:subjects, :subject_id => Sequel[:activities_subjects][:subject_id]).where(Sequel[:activities][:account_id] => acct_id).reverse_order(:activity_date)
   
   erb :show_subjects
end

get('/subjects/new/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @subjects = Subject.where(account_id: acct_id).order(:subject_name)
   
   erb :new_subject
end

post('/subjects/create/:acct_id') do
   a = params['acct_id'].to_i
   
   @subject = Subject.new
   
   @subject.account_id = params['acct_id'].to_i
   @subject.subject_name = params['subject_name']
   @subject.description = params['description']
   @subject.subject_slug = params['subject_name'].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, '')
   
   
#   @subject.save
   #Define variable values from the 'new subject' form
#   account_id = params['acct_id'].to_i
#   subject_name = params[:subject_name]
#   description = params[:description]
#   subject_slug = params[:subject_name].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, '')
   
#   Subject.new do |s|
#      s.account_id = @subject.account_id,
#      s.subject_name = @subject.subject_name,
#      s.description = @subject.description,
#      s.subject_slug = @subject.subject_slug
      
#   end
   
   #Insert values into the db
   Subject.insert(
      :account_id => @subject.account_id,
      :subject_name => @subject.subject_name,
      :description => @subject.description,
      :subject_slug => @subject.subject_slug)
   
   redirect "/accounts/#{a}"
end

get('/subjects/update/:acct_id/:subj_id') do
   account_id = params['acct_id'].to_i
   subject_id = params['subj_id'].to_i
   
   @subject = Subject.where(subject_id: subject_id)
   @subjects = Subject.where(account_id: account_id)
   
   erb :update_subject
end

post('/subjects/create/:acct_id/:subj_id') do
   account_id = params['acct_id'].to_i
   subject_id = params['subj_id'].to_i
   
   subject_name = params[:subject_name]
   description = params[:description]
   subject_slug = params[:subject_name].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, '')
   
   #Update values into the db
   Subject.where(subject_id: subject_id).update(
      :subject_name => subject_name,
      :description => description,
      :subject_slug => subject_slug)
   
   redirect "/accounts/#{account_id}"
end

get('/subjects/change/:subj_id') do
   subject_id = params['subj_id'].to_i
   
   @subject = Subject.where(subject_id: subject_id)
   
   erb :delete_subject
end
   
post('/subjects/delete/:acct_id/:subj_id') do
   account_id = params['acct_id'].to_i
   subject_id = params['subj_id'].to_i
   
   ActivitiesSubject.where(subject_id: subject_id).delete
   BooksSubject.where(subject_id: subject_id).delete
   Subject.where(subject_id: subject_id).delete
   
   redirect "/accounts/#{account_id}"
end

###################################################################### STUDENTS
#Page that displays list of students related to the current account
get('/students/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: acct_id)
   @students = Student.where(account_id: acct_id).order(:birth_date)
   
   erb :show_students
end

#Form for submitting a new student
get('/students/new/:acct_id') do
   acct_id = params['acct_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   
   erb :new_student
end

#Data inserted into the 'students' table in the database
post('/students/create/:acct_id') do
   #Define variable values from the 'new student' form
   account_id = params['acct_id'].to_i
   stud_first_name = params[:stud_first_name]
   stud_last_name = params[:stud_last_name]
   birth_date = params[:birth_date]
   student_slug = params[:stud_first_name].downcase
   
   #Insert values into the db
   Student.insert(
      :account_id => account_id,
      :stud_first_name => stud_first_name, 
      :stud_last_name => stud_last_name,
      :birth_date => birth_date,
      :student_slug => student_slug)
      
   redirect "/accounts/#{account_id}"
end

#Form for updating student info - prepopulated with current info
get('/students/update/:stud_id') do
   stud_id = params['stud_id'].to_i
   
   @student = Student.where(student_id: stud_id)
   
   erb :update_student
end

#All data input is updated for the current row
post('/students/create/:acct_id/:stud_id') do
   acct_id = params['acct_id'].to_i
   
   stud_id = params['stud_id'].to_i
   stud_first_name = params[:stud_first_name]
   stud_last_name = params[:stud_last_name]
   birth_date = params[:birth_date]
   student_slug = params[:stud_first_name].downcase
   
   Student.where(:student_id => stud_id).update(
      :stud_first_name => stud_first_name,
      :stud_last_name => stud_last_name,
      :birth_date => birth_date,
      :student_slug => student_slug)
   
   redirect "/students/#{acct_id}/#{stud_id}"
end

get('/students/change/:acct_id/:stud_id') do
   acct_id = params['acct_id'].to_i
   stud_id = params['stud_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @student = Student.where(student_id: stud_id)
   
   erb :delete_student
end

post('/students/delete/:acct_id/:stud_id') do
   acct_id = params['acct_id'].to_i
   stud_id = params['stud_id'].to_i
   
   ActivitiesStudent.where(student_id: stud_id).delete
   BooksStudent.where(student_id: stud_id).delete
   Student.where(student_id: stud_id).delete
   
   redirect "/accounts/#{acct_id}"
end

################################################################## DETAIL PAGES

#Page to view individual student portfolio
get('/portfolio/:acct_id/:stud_id') do
   acct_id = params['acct_id'].to_i
   stud_id = params['stud_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: acct_id)
   @student = Student.where(student_id: stud_id)
   @subjects = Subject.where(account_id: acct_id).order(:subject_name)
   @activities = ActivitiesStudent.join(:activities, :activity_id => :activity_id).where(student_id: stud_id).reverse_order(:activity_date)
   #@student_subjects = ActivitiesSubject.join(:activities, :activity_id => :activity_id).where(student_id: id).order(:subject_name)
   @student_books = BooksStudent.join(:books, :book_id => :book_id).where(student_id: stud_id).reverse_order(:finish_date)
   
   erb :student_portfolio
end

#Page to view individual activity info
get('/activities/:acct_id/:act_id') do
   acct_id = params['acct_id'].to_i
   act_id = params['act_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: acct_id)
   @activity = Activity.where(activity_id: act_id)
   @activity_students = ActivitiesStudent.join(:students, :student_id => :student_id).where(activity_id: act_id)
   @activity_subjects = ActivitiesSubject.join(:subjects, :subject_id => :subject_id).where(activity_id: act_id)
   
   erb :activity_info
end

#Page to view individual book info
get('/books/:acct_id/:bk_id') do
   acct_id = params['acct_id'].to_i
   bk_id = params['bk_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: acct_id)
   @book = Book.where(book_id: bk_id)
   @book_students = BooksStudent.inner_join(:students, :student_id => :student_id).where(book_id: bk_id)
   @book_subjects = BooksSubject.inner_join(:subjects, :subject_id => :subject_id).where(book_id: bk_id)
   
   erb :book_info
end

#Page to view student personal info
get('/students/:acct_id/:stud_id') do
   acct_id = params['acct_id'].to_i
   stud_id = params['stud_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @student = Student.where(student_id: stud_id)
   
   erb :student_info
end

#Page to view all activities & books for a given subject
get('/subjects/:acct_id/:subj_id') do
   acct_id = params['acct_id'].to_i
   subj_id = params['subj_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @subject = Subject.where(subject_id: subj_id)
   @activities = Activity.join(:activities_subjects, :activity_id => :activity_id).join(:subjects, :subject_id => Sequel[:activities_subjects][:subject_id]).where(Sequel[:activities_subjects][:subject_id] => subj_id).reverse_order(:activity_date)
   @students = Student.join(:activities_students, :student_id => :student_id)
   @books = Book.join(:books_subjects, :book_id => :book_id).join(:subjects, :subject_id => Sequel[:books_subjects][:subject_id]).where(Sequel[:books_subjects][:subject_id] => subj_id).reverse_order(:finish_date)
   @book_students = Student.join(:books_students, :student_id => :student_id)
   
   erb :subject_filter
end

#Page to view all activities & books for a given student and a given subject
get('/portfolio/:acct_id/:stud_id/:subj_id') do
   acct_id = params['acct_id'].to_i
   stud_id = params['stud_id'].to_i
   subj_id = params['subj_id'].to_i
   
   @account = Account.where(account_id: acct_id)
   @student = Student.where(student_id: stud_id)
   @subject = Subject.where(subject_id: subj_id)
   #@activities = Activity.join(:activities_students, :activity_id => :activity_id).join(:students, :student_id => Sequel[:activities_students][:student_id]).join(:activities_subjects, :activity_id => :activity_id).join(:subjects, :subject_id => Sequel[:activities_subjects][:subject_id]).where(Sequel[:activities_students][:student_id] => stud_id).where(Sequel[:activities_subjects][:subject_id] => subj_id)
   @activity_subjects = ActivitiesSubject.join(:activities, :activity_id => :activity_id).where(subject_id: subj_id)
   
   erb :student_subjects
end


#Date.parse('Feb 3, 2010')
# => 2010-2-3
#.parse parses the given representation of date and time and creates a date object