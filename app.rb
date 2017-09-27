require 'sinatra' #load the gem
require 'models_v2' #load the ruby file
require 'erb'
require 'time' #load gem?

#require 'string_helpers' #load gem (allows use of .slug!)

#Set static subjects to a variable
static_subjects = ['Foreign Language', 'Health & Fitness', 'Home Economics', 'Language Arts', 'Mathematics', 'Performing & Visual Arts', 'Science', 'Social Studies', 'Technology']

########################################################################################################################################################################################################################## THE REAL DEAL



#Homepage currently with just a list of account holders
get('/home/') do
   #@accounts = Account.order(:acct_first_name)
   @accounts = Account.by_first_name
   erb :home
end



#Form to create a new account
get('/accounts/new') do
   erb :new_account
end



#Form to login to existing account
get('/accounts/login') do
   erb :login
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Create new_account & insert basic subjects
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
   #Alternate way to snag new account_id (doesn't work)
   #last_id = Account.order(:account_id).last
   
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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Personal account information page
get('/accounts/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth
   
   erb :account_info
end



#Form to update account info
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



#Form to confirm account deletion
get('/accounts/change/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   
   erb :delete_account
end



#Delete selected account and all associated data
post('/accounts/delete/:acct_id') do
   i = params['acct_id'].to_i
   
   #First delete metadata
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
   #@activities = Activity.where(account_id: i).reverse_order(:activity_date).limit(10)
   @activities = Activity.where(account_id: i).by_date.reverse.five
   @activity_subjects = Subject.association_join(:activities_subjects)
   @subjects = Subject.where(account_id: i).by_name
   @books = Book.where(account_id: i).by_date.reverse.five
   @students = Student.where(account_id: i).by_birth
   
   erb :dashboard
end



############################################################################################################################################################################################################################## ACTIVITIES



#List of all activities for a given account
get('/activities/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @activities = Activity.where(account_id: i).by_date.reverse
   
   erb :show_activities
end



#Form for submittig a new activity in a given account
get('/activities/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth.reverse
   @subjects = Subject.where(account_id: i).by_name
  
   erb :new_activity
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to update a particular activity prepopulated with current info
get('/activities/update/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   a = params['act_id'].to_i
   
   @activity = Activity.where(activity_id: a)
   @students = Student.where(account_id: i)
   @subjects = Subject.where(account_id: i)
   
   erb :update_activity
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Update input in the db
post('/activities/create/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   a = params['act_id'].to_i
   
   #Insert said data into the database
   Activity.where(activity_id: a).update(
      :activity_date => params[:activity_date], 
      :title => params[:title],
      :duration => params[:duration],
      :description => params[:description],
      :activity_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
    
   ActivitiesStudent.where(activity_id: a).delete
   ActivitiesSubject.where(activity_id: a).delete
   
   #Insert updated meta data into the activities_students table
   params[:student_id].each do |id|
      ActivitiesStudent.insert(
         :activity_id => a,
         :student_id => id,
         :account_id => i) 
   end
    
   #Insert updated meta data into the activities_subjects table
   params[:subject_id].each do |id|
      ActivitiesSubject.insert(
         :activity_id => a,
         :subject_id => id,
         :account_id => i)
   end
   
   redirect "/activities/#{i}/#{a}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Retrieve the form to confirm deletion of an activity
get('/activities/change/:act_id') do
   a = params['act_id'].to_i
   
   @activity = Activity.where(activity_id: a)
   
   erb :delete_activity
end



#Delete selected activity
post('/activities/delete/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   a = params['act_id'].to_i
   
   ActivitiesStudent.where(activity_id: a).delete
   ActivitiesSubject.where(activity_id: a).delete
   Activity.where(activity_id: a).delete
   
   redirect "/dashboard/#{i}"
end



################################################################################################################################################################################################################################# BOOKS



#Display list of books for a given account
get('/books/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @books = Book.where(account_id: i).by_date.reverse
   
   erb :show_books
end



#Form to submit new book in a given account
get('/books/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth.reverse
   @subjects = Subject.where(account_id: i).by_name
   
   erb :new_book
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Insert new book into 'books' table in the database
post('/books/create/:acct_id') do
   #Assign variables
   i = params['acct_id'].to_i
   
   #Query for db insertion
   Book.insert(
      :account_id => i,
      :title => params[:title], 
      :author => params[:author],
      :fiction => params[:fiction],
      :nonfiction => params[:nonfiction],
      :rating => params[:rating], 
      :finish_date => params[:finish_date],
      #finish_date = Time.parse(params[:finish_date])
      :book_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   
   #Assign variable to the newly-created, auto-incremented book_id   
   last_insert_id = Book.max(:book_id)
   
   #Use the newly-created book instance to populate the related books_students table
   params[:student_id].each do |id|
      BooksStudent.insert(
         :book_id => last_insert_id,
         :student_id => id,
         :account_id => i) 
   end
   
   #Use the newly-created book instance to populate the related books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => last_insert_id,
         :subject_id => id,
         :account_id => i)
   end
   
   redirect "/dashboard/#{i}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to update a particular book prepopulated with current info
get('/books/update/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   @book = Book.where(book_id: b)
   @students = Student.where(account_id: i)
   @subjects = Subject.where(account_id: i)
   
   erb :update_book
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Submit updated input into the db
post('/books/create/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   #Insert said data into the database
   Book.where(book_id: b).update(
      :finish_date => params[:finish_date], 
      :title => params[:title],
      :author => params[:author],
      :rating => params[:rating],
      :fiction => params[:fiction],
      :nonfiction => params[:nonfiction],
      :book_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   
   #Clear meta students & subjects rows related to current book entirely so they can be deleted or added to based on new selections 
   BooksStudent.where(book_id: b).delete
   BooksSubject.where(book_id: b).delete
   
   #Insert updated meta data into the books_students table
   params[:student_id].each do |id|
      BooksStudent.insert(
         :book_id => b,
         :student_id => id,
         :account_id => i) 
   end
    
   #Insert updated meta data into the books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => b,
         :subject_id => id,
         :account_id => i)
   end
   
   redirect "/dashboard/#{i}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Get form to confirm deletion of said book
get('/books/change/:book_id') do
   b = params['book_id'].to_i
   
   @book = Book.where(book_id: b)
   
   erb :delete_book
end



#Delete selected book
post('/books/delete/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   BooksStudent.where(book_id: b).delete
   BooksSubject.where(book_id: b).delete
   Book.where(book_id: b).delete
   
   redirect "/dashboard/#{i}"
end



#View all books by selected author in selected account
get('/books/author/:acct_id/:author') do
   i = params['acct_id'].to_i
   author = params['author']
   
   @books = Book.where(account_id: i).where(Sequel.like(:author, "#{author}%"))
   
   erb :show_author
end



#View all books by selected author, read by selected student, in selected account
get('/books/author/:acct_id/:stud_id/:author') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   author = params['author']
   
   @books = Book.association_join(:books_students).where(Sequel[:books_students][:account_id] => i).where(Sequel[:books_students][:student_id] => s).where(Sequel.like(:author, "#{author}%"))
   
   erb :student_author
end



################################################################################################################################################################################################################################ SUBJECTS



#Page that displays list of subjects with all related activities
get('/subjects/:acct_id') do
   i = params['acct_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @subjects = Subject.where(account_id: i).by_name
   @activities = Activity.association_join(:activities_subjects).join(:subjects, :subject_id => Sequel[:activities_subjects][:subject_id]).where(Sequel[:activities][:account_id] => i).by_date.reverse
   
   erb :show_subjects
end



#Form for creating a new subject for said account
get('/subjects/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @subjects = Subject.where(account_id: i).by_name
   
   erb :new_subject
end



#Insert new subject into db for said account
post('/subjects/create/:acct_id') do
   i = params['acct_id'].to_i
   
   #Insert values into the db
   Subject.insert(
      :account_id => i,
      :subject_name => params['subject_name'],
      :description => params['description'],
      :subject_slug => params['subject_name'].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   
   redirect "/accounts/#{i}"
end



#Form to edit a subject
get('/subjects/update/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   @subject = Subject.where(subject_id: j)
   @subjects = Subject.where(account_id: i)
   
   erb :update_subject
end



#Update the subject in the db
post('/subjects/create/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   #Update values into the db
   Subject.where(subject_id: j).update(
      :subject_name => params[:subject_name],
      :description => params[:description],
      :subject_slug => params[:subject_name].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   
   redirect "/accounts/#{i}"
end



#Form to delete a subject
get('/subjects/change/:subj_id') do
   j = params['subj_id'].to_i
   
   @subject = Subject.where(subject_id: j)
   
   erb :delete_subject
end



#Delete selected subject from subjects and metadata tables   
post('/subjects/delete/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   ActivitiesSubject.where(subject_id: j).delete
   BooksSubject.where(subject_id: j).delete
   Subject.where(subject_id: j).delete
   
   redirect "/accounts/#{i}"
end



############################################################################################################################################################################################################################### STUDENTS



#Page that displays list of students related to the current account
get('/students/:acct_id') do
   i = params['acct_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth
   
   erb :show_students
end



#Form for submitting a new student
get('/students/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   
   erb :new_student
end



#Data inserted into the 'students' table in the database
post('/students/create/:acct_id') do
   i = params['acct_id'].to_i
   
   #Insert values into the db
   Student.insert(
      :account_id => i,
      :stud_first_name => params[:stud_first_name], 
      :stud_last_name => params[:stud_last_name],
      :birth_date => params[:birth_date],
      :student_slug => params[:stud_first_name].downcase)
      
   redirect "/accounts/#{i}"
end



#Form for updating student info - prepopulated with current info
get('/students/update/:stud_id') do
   s = params['stud_id'].to_i
   
   @student = Student.where(student_id: s)
   
   erb :update_student
end



#All data input is updated for the current row
post('/students/create/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   Student.where(:student_id => s).update(
      :stud_first_name => params[:stud_first_name],
      :stud_last_name => params[:stud_last_name],
      :birth_date => params[:birth_date],
      :student_slug => params[:stud_first_name].downcase)
   
   redirect "/students/#{i}/#{s}"
end



#Form to confirm student deletion
get('/students/change/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s)
   
   erb :delete_student
end



#Delete selected student from students table and metadata
post('/students/delete/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   ActivitiesStudent.where(student_id: s).delete
   BooksStudent.where(student_id: s).delete
   Student.where(student_id: s).delete
   
   redirect "/accounts/#{i}"
end



########################################################################################################################################################################################################################### DETAIL PAGES



#Page to view individual student portfolio
get('/portfolio/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s)
   @subjects = Subject.where(account_id: i).by_name
   @activities = Activity.association_join(:activities_students).where(student_id: s).by_date.reverse
   @books = Book.association_join(:books_students).where(student_id: s).by_date.reverse
   
   erb :student_portfolio
end



#Page to view individual activity info
get('/activities/:acct_id/:act_id') do
   i = params['acct_id'].to_i
   a = params['act_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @activity = Activity.where(activity_id: a)
   @students = Student.association_join(:activities_students).where(activity_id: a)
   @subjects = Subject.association_join(:activities_subjects).where(activity_id: a)
   
   erb :activity_info
end



#Page to view individual book info
get('/books/:acct_id/:bk_id') do
   i = params['acct_id'].to_i
   b = params['bk_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @book = Book.where(book_id: b)
   @students = Student.association_join(:books_students).where(book_id: b)
   @subjects = Subject.association_join(:books_subjects).where(book_id: b)
   
   erb :book_info
end



#Page to view student personal info
get('/students/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s)
   
   erb :student_info
end



#Page to view all activities & books for a given subject
get('/subjects/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   #@account = Account.where(account_id: i)
   @subject = Subject.where(subject_id: j, account_id: i)
   @activities = Activity.association_join(:activities_subjects).join(:subjects, :subject_id => Sequel[:activities_subjects][:subject_id]).where(Sequel[:activities_subjects][:subject_id] => j).by_date.reverse
   @students = Student.association_join(:activities_students)
   @books = Book.association_join(:books_subjects).join(:subjects, :subject_id => Sequel[:books_subjects][:subject_id]).where(Sequel[:books_subjects][:subject_id] => j).by_date.reverse
   @book_students = Student.association_join(:books_students)
   
   erb :subject_filter
end



#Page to view all activities & books for a given student and a given subject
get('/portfolio/:acct_id/:stud_id/:subj_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   j = params['subj_id'].to_i
   
   #@account = Account.where(account_id: i)
   @student = Student.where(student_id: s, account_id: i)
   @subject = Subject.where(subject_id: j)
   @activities = Activity.association_join(:activities_subjects).where(subject_id: j).association_join(:activities_students).where(student_id: s)
   @books = Book.association_join(:books_subjects).where(subject_id: j).association_join(:books_students).where(student_id: s)
   
   erb :student_subjects
end


#Date.parse('Feb 3, 2010')
# => 2010-2-3
#.parse parses the given representation of date and time and creates a date object