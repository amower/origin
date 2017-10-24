require 'sinatra' #load the gem
require 'models' #load the ruby file
require 'erb'
require 'time' #load gem?
enable :sessions

#require 'string_helpers' #load gem (allows use of .slug!)

#Set static subjects to a variable
static_subjects = ['Foreign Language', 'Health & Fitness', 'Home Economics', 'Language Arts', 'Mathematics', 'Performing & Visual Arts', 'Science', 'Social Studies', 'Technology']

########################################################################################################################################################################################################################## THE REAL DEAL



#Homepage currently with just a list of account holders
get('/') do
   @message = session.delete(:message)
   session.clear
   @accounts = Account.by_first_name
   
   #Templates take a second argument, the options hash. Here I disable the layout for this file.
   erb :home, :layout => false
end



#Form to create a new account
get('/registrations/signup') do
   erb :'registrations/signup', :layout => false
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Create new_account & insert basic subjects
post('/registrations') do
   #Insert new_account form values into accounts table as new object
   #Account.insert(
   #   :acct_first_name => params[:acct_first_name],
   #   :acct_last_name => params[:acct_last_name],
   #   :zipcode => params[:zipcode],
   #   :email => params[:email],
   #   :password => params[:password],
   #   :join_date => params[:join_date],
   #   :account_hash => params[:acct_last_name].downcase)
      
   @account = Account.new(
      :acct_first_name => params[:acct_first_name],
      :acct_last_name => params[:acct_last_name],
      :zipcode => params[:zipcode],
      :email => params[:email],
      :password => params[:password],
      :join_date => params[:join_date],
      :account_hash => params[:acct_last_name].downcase)
   
   @account.save
     
   session[:id] = @account.account_id
   session[:message] = "Thank you for creating your education portfolio account! Let's get started by Adding Students to your account."
   
   #Snag newly-created auto-incremented account_id  
   #last_insert_id = Account.max(:account_id)
   
   #Alternate way to snag new account_id (doesn't work)
   #last_id = Account.order(:account_id).last
   
   #Insert basic subjects automatically when new account is created
   static_subjects.each do |name|
      Subject.insert(
         :account_id => session[:id],
         :subject_name => name,
         :subject_slug => name.downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   end
   
   #Go immediately to account info page   
   #redirect "/dashboard/#{session[:id]}"
   redirect '/account/dashboard'
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to log in to existing account
get('/sessions/login') do
   erb :'sessions/login', :layout => false
end



post('/sessions') do
   @account = Account.where(email: params[:email], password: params[:password]).first
   session[:id] = @account.account_id
   session[:message] = "Welcome back!"
   
   redirect '/account/dashboard'
end



get('/sessions/logout') do
   session.clear
   
   session[:message] = "You have successfully logged out."
   
   redirect '/'
end



#Personal Account Dashboard
#get('/dashboard/:acct_id') do
get('/account/dashboard') do
   #@id = session[:id]
   @account = Account.where(account_id: session[:id])
   #@account = Account.where(account_id: @id)
   #@account = Account[@id]
   
   #i = params['acct_id'].to_i
   @message = session.delete(:message)
   
   #@account = Account.where(account_id: i)
   @activities = Activity.where(account_id: session[:id]).by_date.reverse.ten
   @activity_subjects = Subject.association_join(:activities_subjects)
   @subjects = Subject.where(account_id: session[:id]).by_name
   @books = Book.where(account_id: session[:id]).by_date.reverse.ten
   @students = Student.where(account_id: session[:id]).by_birth
   
   erb :'show/dashboard'
end



#Personal account information page
get('/account/profile') do ###########I'm changing this w/o updating connections!!!!!#######################################################
   #i = params['acct_id'].to_i
   #@id = session[:id]
   @message = session.delete(:message)
   @account = Account.where(account_id: session[:id])
   
   erb :'info/account_info'
end



#Form to update account info
get('/account/profile/update') do
   #i = params['acct_id'].to_i
   #@id = session[:id]
   
   @account = Account.where(account_id: session[:id])
   
   erb :'update/update_account'
end



#Update an existing account
post('/account/profile/create') do
   #i = params['acct_id'].to_i
   #@id = session[:id]
   session[:message] = "Your profile has been updated."
   
   Account.where(:account_id => session[:id]).update(
      :acct_first_name => params[:acct_first_name],
      :acct_last_name => params[:acct_last_name],
      :zipcode => params[:zipcode],
      :email => params[:email],
      :password => params[:password],
      :account_hash => params[:acct_last_name].downcase)
   
   redirect "/account/profile"
end



#Form to confirm account deletion
get('/account/profile/change') do
   #i = params['acct_id'].to_i
   #@id = session[:id]
   
   @account = Account.where(account_id: session[:id])
   
   erb :'delete/delete_account'
end



#Delete selected account and all associated data
post('/account/profile/delete') do
   #i = params['acct_id'].to_i
   #@id = session[:id]
   session[:message] = "Your account was deleted."
   
   #First delete metadata
   ActivitiesStudent.where(:account_id => session[:id]).delete
   ActivitiesSubject.where(:account_id => session[:id]).delete
   Activity.where(:account_id => session[:id]).delete
   BooksStudent.where(:account_id => session[:id]).delete
   BooksSubject.where(:account_id => session[:id]).delete
   Book.where(:account_id => session[:id]).delete
   Subject.where(:account_id => session[:id]).delete
   Student.where(:account_id => session[:id]).delete
   Account.where(:account_id => session[:id]).delete
   
   redirect "/"
end



############################################################################################################################################################################################################################## ACTIVITIES



#List of all activities for a given account
get('/activities/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @activities = Activity.where(account_id: i).by_date.reverse
   
   erb :'show/show_activities'
end



#Form for submittig a new activity in a given account
get('/activities/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth.reverse
   @subjects = Subject.where(account_id: i).by_name
  
   erb :'new/new_activity'
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
      :duration => params[:hrs].to_i * 60 + params[:mins].to_i,
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
get('/activities/update/:acct_id/:actv_id') do
   i = params['acct_id'].to_i
   a = params['actv_id'].to_i
   
   @account = Account.where(account_id: i)
   @activity = Activity.where(activity_id: a)
   @students = Student.where(account_id: i)
   @subjects = Subject.where(account_id: i)
   @activities_students = ActivitiesStudent.where(activity_id: a)
   @activities_subjects = ActivitiesSubject.where(activity_id: a)
   
   erb :'update/update_activity'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Update activity info in the db
post('/activities/create/:acct_id/:actv_id') do
   i = params['acct_id'].to_i
   a = params['actv_id'].to_i
   
   #Insert said data into the database
   Activity.where(activity_id: a).update(
      :activity_date => params[:activity_date], 
      :title => params[:title],
      :duration => params[:hrs].to_i * 60 + params[:mins].to_i,
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
get('/activities/change/:acct_id/:actv_id') do
   i = params['acct_id'].to_i
   a = params['actv_id'].to_i
   
   @account = Account.where(account_id: i)
   @activity = Activity.where(activity_id: a)
   
   erb :'delete/delete_activity'
end



#Delete selected activity
post('/activities/delete/:acct_id/:actv_id') do
   i = params['acct_id'].to_i
   a = params['actv_id'].to_i
   
   ActivitiesStudent.where(activity_id: a).delete
   ActivitiesSubject.where(activity_id: a).delete
   Activity.where(activity_id: a).delete
   
   redirect "/activities/#{i}"
end



################################################################################################################################################################################################################################# BOOKS



#Display list of books for a given account
get('/books/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @books = Book.where(account_id: i).by_date.reverse
   
   erb :'show/show_books'
end



#Form to submit new book in a given account
get('/books/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @students = Student.where(account_id: i).by_birth.reverse
   @subjects = Subject.where(account_id: i).by_name
   
   erb :'new/new_book'
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
      :subtitle => params[:subtitle],
      :prefix => params[:prefix],
      :first_name => params[:first_name],
      :middle_name => params[:middle_name],
      :last_name => params[:last_name],
      :suffix => params[:suffix],
      :category => params[:category],
      :rating => params[:rating], 
      :finish_date => params[:finish_date],
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
   
   redirect "/books/#{i}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to update a particular book prepopulated with current info
get('/books/update/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   @account = Account.where(account_id: i)
   @book = Book.where(book_id: b)
   @students = Student.where(account_id: i)
   @subjects = Subject.where(account_id: i)
   @books_students = BooksStudent.where(book_id: b)
   @books_subjects = BooksSubject.where(book_id: b)
   
   erb :'update/update_book'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Submit updated book data into the db
post('/books/create/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   #Insert said data into the database
   Book.where(book_id: b).update(
      :finish_date => params[:finish_date], 
      :title => params[:title],
      :subtitle => params[:subtitle],
      :prefix => params[:prefix],
      :first_name => params[:first_name],
      :middle_name => params[:middle_name],
      :last_name => params[:last_name],
      :suffix => params[:suffix],
      :rating => params[:rating],
      :category => params[:category],
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
   
   redirect "/books/#{i}/#{b}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Get form to confirm deletion of said book
get('/books/change/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   @account = Account.where(account_id: i)
   @book = Book.where(book_id: b)
   
   erb :'delete/delete_book'
end



#Delete selected book
post('/books/delete/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   BooksStudent.where(book_id: b).delete
   BooksSubject.where(book_id: b).delete
   Book.where(book_id: b).delete
   
   redirect "/books/#{i}"
end



#View books by authors on account sorted alphabetically
get('/books/sort/:acct_id/:letter') do
   i = params['acct_id'].to_i
   l = params['letter']
   
   @account = Account.where(account_id: i)
   @books = Book.where(account_id: i).where(Sequel.like(:last_name, "#{l}%")).by_date.reverse
   
   erb :'show/sort_author'
end



#View all books by selected author in selected account
get('/books/author/:acct_id/:name') do
   i = params['acct_id'].to_i
   last_name = params['name']
   
   @account = Account.where(account_id: i)
   @books = Book.where(account_id: i).where(Sequel.like(:last_name, "#{last_name}%")).by_date.reverse
   
   erb :'show/show_author'
end



#View all books by selected author, read by selected student, in selected account
get('/books/author/:acct_id/:stud_id/:name') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   last_name = params['name']
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s, account_id: i)
   @books = Book.association_join(:books_students).where(student_id: s).where(Sequel.like(:last_name, "#{last_name}%")).by_date.reverse
   
   erb :'show/student_author'
end



################################################################################################################################################################################################################################ SUBJECTS



#Page that displays list of subjects and links to individual subject pages
get('/subjects/:acct_id') do
   i = params['acct_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @subjects = Subject.where(account_id: i).by_name
   @activities = Activity.association_join(:activities_subjects)
   @books = Book.association_join(:books_subjects)
   
   erb :'show/show_subjects'
end



#Page for managing subjects on the account
get('/subjects/manage/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @subjects = Subject.where(account_id: i).by_name
   
   erb :'show/manage_subjects'
end



#Form for creating a new subject for said account
get('/subjects/new/:acct_id') do
   i = params['acct_id'].to_i
   
   @account = Account.where(account_id: i)
   @subjects = Subject.where(account_id: i).by_name
   
   erb :'new/new_subject'
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
   
   redirect "/subjects/manage/#{i}"
end



#Form to edit a subject
get('/subjects/update/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   @account = Account.where(account_id: i)
   @subject = Subject.where(subject_id: j)
   @subjects = Subject.where(account_id: i).by_name
   
   erb :'update/update_subject'
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
   
   redirect "/subjects/manage/#{i}"
end



#Form to delete a subject
get('/subjects/change/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   @account = Account.where(account_id: i)
   @subject = Subject.where(subject_id: j)
   
   erb :'delete/delete_subject'
end



#Delete selected subject from subjects and metadata tables   
post('/subjects/delete/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   ActivitiesSubject.where(subject_id: j).delete
   BooksSubject.where(subject_id: j).delete
   Subject.where(subject_id: j).delete
   
   redirect "/subjects/manage/#{i}"
end



############################################################################################################################################################################################################################### STUDENTS



#Page that displays list of students related to the current account
get('account/students') do
   #i = params['acct_id'].to_i
   #@id = session[:id]
   
   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @students = Student.where(account_id: session[:id]).by_birth
   
   erb :'show/manage_students'
end



#Form for submitting a new student
get('/account/students/new') do
   #i = params['acct_id'].to_i
   
   @account = Account.where(account_id: session[:id])
   
   erb :'new/new_student'
end



#Data inserted for new student
post('/account/students/create') do
   #i = params['acct_id'].to_i
   
   #Insert values into the db
   Student.insert(
      :account_id => session[:id],
      :stud_first_name => params[:stud_first_name], 
      :stud_last_name => params[:stud_last_name],
      :birth_date => params[:birth_date],
      :student_slug => params[:stud_first_name].downcase)
      
   redirect "/account/students"
end



#Form for updating student info - prepopulated with current info
get('/students/update/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s)
   
   erb :'update/update_student'
end



#Update student info
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
   
   erb :'delete/delete_student'
end



#Delete selected student from students table and metadata
post('/students/delete/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   ActivitiesStudent.where(student_id: s).delete
   BooksStudent.where(student_id: s).delete
   Student.where(student_id: s).delete
   
   redirect "/students/#{i}"
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
   
   erb :'show/student_portfolio'
end



#Page to view individual activity info
get('/activities/:acct_id/:actv_id') do
   i = params['acct_id'].to_i
   a = params['actv_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @activity = Activity.where(activity_id: a)
   @students = Student.association_join(:activities_students).where(activity_id: a).by_birth
   @subjects = Subject.association_join(:activities_subjects).where(activity_id: a).by_name
   
   erb :'info/activity_info'
end



#Page to view individual book info
get('/books/:acct_id/:book_id') do
   i = params['acct_id'].to_i
   b = params['book_id'].to_i
   
   #Define instance variables for filtering
   @account = Account.where(account_id: i)
   @book = Book.where(book_id: b)
   @students = Student.association_join(:books_students).where(book_id: b).by_birth
   @subjects = Subject.association_join(:books_subjects).where(book_id: b).by_name
   
   erb :'info/book_info'
end



#Page to view individual student info
get('/students/:acct_id/:stud_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s)
   
   erb :'info/student_info'
end



#Page to view all activities & books for a given subject
get('/subjects/:acct_id/:subj_id') do
   i = params['acct_id'].to_i
   j = params['subj_id'].to_i
   
   @account = Account.where(account_id: i)
   @subject = Subject.where(subject_id: j, account_id: i)
   @activities = Activity.association_join(:activities_subjects).where(subject_id: j).by_date.reverse
   @students = Student.association_join(:activities_students).by_birth
   @books = Book.association_join(:books_subjects).where(subject_id: j).by_date.reverse
   @book_students = Student.association_join(:books_students)
   
   erb :'show/subject_filter'
end



#Page to view all activities & books for a given student and a given subject
get('/portfolio/:acct_id/:stud_id/:subj_id') do
   i = params['acct_id'].to_i
   s = params['stud_id'].to_i
   j = params['subj_id'].to_i
   
   @account = Account.where(account_id: i)
   @student = Student.where(student_id: s, account_id: i)
   @subject = Subject.where(subject_id: j)
   @activities = Activity.association_join(:activities_subjects).where(subject_id: j).association_join(:activities_students).where(student_id: s).by_date.reverse
   @books = Book.association_join(:books_subjects).where(subject_id: j).association_join(:books_students).where(student_id: s).by_date.reverse
   
   erb :'show/student_subjects'
end
