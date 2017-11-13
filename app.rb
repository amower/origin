require 'sinatra' #load the gem
require 'models' #load the ruby file
require 'erb'
require 'time' #load gem
enable :sessions #allows use of session

#Set static subjects to a variable
static_subjects = ['Foreign Language', 'Health & Fitness', 'Home Economics', 'Language Arts', 'Mathematics', 'Performing & Visual Arts', 'Science', 'Social Studies', 'Technology']

########################################################################################################################################################################################################################## THE REAL DEAL



#Homepage displays 'logged out' message if needed and clears the session
get('/') do
   #Put the session[:message] from the previous path into a variable for one-time use.
   @message = session.delete(:message)


   #Templates take a second argument, the options hash. Here I disable the layout for this file.
   erb :home, :layout => :public_layout
end



#Form to create a new account
get('/registrations/signup') do
   #Disable the layout for this file
   erb :'registrations/signup', :layout => :public_layout
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Create new_account & insert basic subjects
post('/registrations') do
   #Insert new_account form values into accounts table as new object
   @account = Account.new(
      :acct_first_name => params[:acct_first_name],
      :acct_last_name => params[:acct_last_name],
      :zipcode => params[:zipcode],
      :email => params[:email],
      :password => params[:password],
      :join_date => params[:join_date],
      :account_hash => params[:acct_last_name].downcase)

   #Save is required after 'new' - and to get session[:id]
   @account.save

   #session[:id] stays valid through all get/post requests until session is cleared - this replaces all url :params that used to pass around the account id from one request to another.
   session[:id] = @account.account_id

   #This message will be passed into a variable and displayed on the next template.
   session[:message] = "Congratulations on creating your education portfolio account! Get started by adding students to your account."

   #Insert basic subjects automatically when new account is created
   static_subjects.each do |name|
      Subject.insert(
         :account_id => session[:id],
         :subject_name => name,
         :subject_slug => name.downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))
   end

   #Go immediately to account dashboard
   redirect '/account/dashboard'
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


#Form to log in to existing account
get('/sessions/login') do
   erb :'sessions/login', :layout => :public_layout
end



#Login verification & setting of session id & session login message
post('/sessions') do
   #Find account by email & password match
   @account = Account.where(email: params[:email], password: params[:password]).first

   #Set session[:id] to current account_id
   session[:id] = @account.account_id

   #Find first name of account holder
   name = @account.acct_first_name

   #Set message for display on dashboard upon successful login
   session[:message] = "Welcome back, #{name}!"

   redirect '/account/dashboard'
end



#Logout and clear session data & set session logout message
get('/sessions/logout') do
   session.clear

   session[:message] = "You have successfully logged out."

   redirect '/'
end



#Personal Account Dashboard
get('/account/dashboard') do
   @account = Account.where(account_id: session[:id])

   #One-time display of login message
   @message = session.delete(:message)

   #Assign all session-related datasets
   @activities = Activity.where(account_id: session[:id]).by_date.reverse.ten
   @activity_subjects = Subject.association_join(:activities_subjects)
   @subjects = Subject.where(account_id: session[:id]).by_name
   @books = Book.where(account_id: session[:id]).by_date.reverse.ten
   @students = Student.where(account_id: session[:id]).by_birth

   erb :'show/dashboard'
end



#Personal account profile page
get('/account/profile') do
   #One-time display of profile-updated message (set in account/profile/create)
   @message = session.delete(:message)

   @account = Account.where(account_id: session[:id])

   erb :'info/account_info'
end



#Form to update account info
get('/account/profile/update') do

   @account = Account.where(account_id: session[:id])

   erb :'update/update_account'
end



#Update an existing account
post('/account/profile/create') do
   #Set message for updated profile (for display on account/profile page)
   session[:message] = "Your profile has been updated."

   #Update account info
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

   @account = Account.where(account_id: session[:id])

   erb :'delete/delete_account'
end



#Delete selected account and all associated data
post('/account/profile/delete') do
   #Set message to display on homepage after account deletion
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
get('/account/activities') do
   #One-time use of activity-deleted message from post request
   @message = session.delete(:message)

   @account = Account.where(account_id: session[:id])
   @activities = Activity.where(account_id: session[:id]).by_date.reverse

   erb :'show/show_activities'
end



#Form for submittig a new activity in a given account
get('/account/activities/new') do

   @account = Account.where(account_id: session[:id])
   @students = Student.where(account_id: session[:id]).by_birth.reverse
   @subjects = Subject.where(account_id: session[:id]).by_name

   erb :'new/new_activity'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Insert rows from the 'new activity' form into the database
post('/account/activities/create') do
   #Insert activity data into the database
   Activity.insert(
      :account_id => session[:id],
      :activity_date => params[:activity_date],
      :title => params[:title],
      :duration => params[:hrs].to_i * 60 + params[:mins].to_i,
      :description => params[:description],
      :activity_slug => params[:title].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))

   #Grab the newly-created auto-incremented activity_id on this account
   last_insert_id = Activity.where(account_id: session[:id]).max(:activity_id)

   #Insert meta data into the activities_students table
   params[:student_id].each do |id|
      ActivitiesStudent.insert(
         :activity_id => last_insert_id,
         :student_id => id,
         :account_id => session[:id])
   end

   #Insert meta data into the activities_subjects table
   params[:subject_id].each do |id|
      ActivitiesSubject.insert(
         :activity_id => last_insert_id,
         :subject_id => id,
         :account_id => session[:id])
   end

   redirect "/account/activities"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to update a particular activity prepopulated with current info
get('/account/activities/update/:actv_id') do
   a = params['actv_id'].to_i

   #Assign datasets to variables
   @account = Account.where(account_id: session[:id])
   @activity = Activity.where(activity_id: a)
   @students = Student.where(account_id: session[:id])
   @subjects = Subject.where(account_id: session[:id])
   @activities_students = ActivitiesStudent.where(activity_id: a)
   @activities_subjects = ActivitiesSubject.where(activity_id: a)

   erb :'update/update_activity'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Update activity info in the db
post('/account/activities/create/:actv_id') do
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
         :account_id => session[:id])
   end

   #Insert updated meta data into the activities_subjects table
   params[:subject_id].each do |id|
      ActivitiesSubject.insert(
         :activity_id => a,
         :subject_id => id,
         :account_id => session[:id])
   end

   redirect "/account/activities/#{a}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Retrieve the form to confirm deletion of an activity
get('/account/activities/change/:actv_id') do
   a = params['actv_id'].to_i

   @account = Account.where(account_id: session[:id])
   @activity = Activity.where(activity_id: a)

   erb :'delete/delete_activity'
end



#Delete selected activity
post('/account/activities/delete/:actv_id') do
   a = params['actv_id'].to_i

   #Set deleted activity message for account/activities page
   session[:message] = "Your activity was deleted successfully."

   ActivitiesStudent.where(activity_id: a).delete
   ActivitiesSubject.where(activity_id: a).delete
   Activity.where(activity_id: a).delete

   redirect "/account/activities"
end



################################################################################################################################################################################################################################# BOOKS



#Display list of books for a given account
get('/account/books') do

   @account = Account.where(account_id: session[:id])
   @books = Book.where(account_id: session[:id]).by_date.reverse

   erb :'show/show_books'
end



#Form to submit new book in a given account
get('/account/books/new') do

   @account = Account.where(account_id: session[:id])
   @students = Student.where(account_id: session[:id]).by_birth.reverse
   @subjects = Subject.where(account_id: session[:id]).by_name

   erb :'new/new_book'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Insert new book into 'books' table in the database
post('/account/books/create') do
   #Query for db insertion
   Book.insert(
      :account_id => session[:id],
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
         :account_id => session[:id])
   end

   #Use the newly-created book instance to populate the related books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => last_insert_id,
         :subject_id => id,
         :account_id => session[:id])
   end

   redirect "/account/books"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Form to update a particular book prepopulated with current info
get('/account/books/update/:book_id') do
   b = params['book_id'].to_i

   @account = Account.where(account_id: session[:id])
   @book = Book.where(book_id: b)
   @students = Student.where(account_id: session[:id])
   @subjects = Subject.where(account_id: session[:id])
   @books_students = BooksStudent.where(book_id: b)
   @books_subjects = BooksSubject.where(book_id: b)

   erb :'update/update_book'
end



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Submit updated book data into the db
post('/account/books/create/:book_id') do
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
         :account_id => session[:id])
   end

   #Insert updated meta data into the books_subjects table
   params[:subject_id].each do |id|
      BooksSubject.insert(
         :book_id => b,
         :subject_id => id,
         :account_id => session[:id])
   end

   redirect "/account/books/#{b}"
end
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



#Get form to confirm deletion of said book
get('/account/books/change/:book_id') do
   b = params['book_id'].to_i

   @account = Account.where(account_id: session[:id])
   @book = Book.where(book_id: b)

   erb :'delete/delete_book'
end



#Delete selected book
post('/account/books/delete/:book_id') do
   b = params['book_id'].to_i

   BooksStudent.where(book_id: b).delete
   BooksSubject.where(book_id: b).delete
   Book.where(book_id: b).delete

   redirect "/account/books"
end



#View books by authors on account sorted alphabetically
get('/account/books/sort/:letter') do
   l = params['letter']

   @account = Account.where(account_id: session[:id])
   @books = Book.where(account_id: session[:id]).where(Sequel.like(:last_name, "#{l}%")).by_date.reverse

   erb :'show/sort_author'
end



#View all books by selected author in selected account
get('/account/books/author/:name') do
   last_name = params['name']

   @account = Account.where(account_id: session[:id])
   @books = Book.where(account_id: session[:id]).where(Sequel.like(:last_name, "#{last_name}%")).by_date.reverse

   erb :'show/show_author'
end



#View all books by selected author, read by selected student, in selected account
get('/account/books/author/:stud_id/:name') do
   s = params['stud_id'].to_i
   last_name = params['name']

   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s, account_id: session[:id])
   @books = Book.association_join(:books_students).where(student_id: s).where(Sequel.like(:last_name, "#{last_name}%")).by_date.reverse

   erb :'show/student_author'
end



################################################################################################################################################################################################################################ SUBJECTS



#Page that displays list of subjects and links to individual subject pages
get('/account/subjects') do

   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @subjects = Subject.where(account_id: session[:id]).by_name
   @activities = Activity.association_join(:activities_subjects)
   @books = Book.association_join(:books_subjects)

   erb :'show/show_subjects'
end



#Page for managing subjects on the account
get('/account/subjects/manage') do

   @account = Account.where(account_id: session[:id])
   @subjects = Subject.where(account_id: session[:id]).by_name

   erb :'show/manage_subjects'
end



#Form for creating a new subject for said account
get('/account/subjects/new') do

   @account = Account.where(account_id: session[:id])
   @subjects = Subject.where(account_id: session[:id]).by_name

   erb :'new/new_subject'
end



#Insert new subject into db for said account
post('/account/subjects/create') do

   #Insert values into the db
   Subject.insert(
      :account_id => session[:id],
      :subject_name => params['subject_name'],
      :description => params['description'],
      :subject_slug => params['subject_name'].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))

   redirect "/account/subjects/manage"
end



#Form to edit a subject
get('/account/subjects/update/:subj_id') do
   j = params['subj_id'].to_i

   @account = Account.where(account_id: session[:id])
   @subject = Subject.where(subject_id: j)
   @subjects = Subject.where(account_id: session[:id]).by_name

   erb :'update/update_subject'
end



#Update the subject in the db
post('/account/subjects/create/:subj_id') do
   j = params['subj_id'].to_i

   #Update values into the db
   Subject.where(subject_id: j).update(
      :subject_name => params[:subject_name],
      :description => params[:description],
      :subject_slug => params[:subject_name].downcase.strip.gsub(' ', '-').gsub('&', 'and').gsub(/[^\w-]/, ''))

   redirect "/account/subjects/manage"
end



#Form to delete a subject
get('/account/subjects/change/:subj_id') do
   j = params['subj_id'].to_i

   @account = Account.where(account_id: session[:id])
   @subject = Subject.where(subject_id: j)

   erb :'delete/delete_subject'
end



#Delete selected subject from subjects and metadata tables
post('/account/subjects/delete/:subj_id') do
   j = params['subj_id'].to_i

   ActivitiesSubject.where(subject_id: j).delete
   BooksSubject.where(subject_id: j).delete
   Subject.where(subject_id: j).delete

   redirect "/account/subjects/manage"
end



############################################################################################################################################################################################################################### STUDENTS



#Page that displays list of students related to the current account
get('/account/students') do

   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @students = Student.where(account_id: session[:id]).by_birth

   erb :'show/manage_students'
end



#Form for submitting a new student
get('/account/students/new') do

   @account = Account.where(account_id: session[:id])

   erb :'new/new_student'
end



#Data inserted for new student
post('/account/students/create') do
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
get('/account/students/update/:stud_id') do
   s = params['stud_id'].to_i

   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s)

   erb :'update/update_student'
end



#Update student info
post('/account/students/create/:stud_id') do
   s = params['stud_id'].to_i

   Student.where(:student_id => s).update(
      :stud_first_name => params[:stud_first_name],
      :stud_last_name => params[:stud_last_name],
      :birth_date => params[:birth_date],
      :student_slug => params[:stud_first_name].downcase)

   redirect "/account/students/#{s}"
end



#Form to confirm student deletion
get('/account/students/change/:stud_id') do
   s = params['stud_id'].to_i

   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s)

   erb :'delete/delete_student'
end



#Delete selected student from students table and metadata
post('/account/students/delete/:stud_id') do
   s = params['stud_id'].to_i

   ActivitiesStudent.where(student_id: s).delete
   BooksStudent.where(student_id: s).delete
   Student.where(student_id: s).delete

   redirect "/account/students"
end



########################################################################################################################################################################################################################### DETAIL PAGES



#Page to view individual student portfolio
get('/account/portfolio/:stud_id') do
   s = params['stud_id'].to_i

   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s)
   @subjects = Subject.where(account_id: session[:id]).by_name
   @activities = Activity.association_join(:activities_students).where(student_id: s).by_date.reverse
   @books = Book.association_join(:books_students).where(student_id: s).by_date.reverse

   erb :'show/student_portfolio'
end



#Page to view individual activity info
get('/account/activities/:actv_id') do
   a = params['actv_id'].to_i

   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @activity = Activity.where(activity_id: a)
   @students = Student.association_join(:activities_students).where(activity_id: a).by_birth
   @subjects = Subject.association_join(:activities_subjects).where(activity_id: a).by_name

   erb :'info/activity_info'
end



#Page to view individual book info
get('/account/books/:book_id') do
   b = params['book_id'].to_i

   #Define instance variables for filtering
   @account = Account.where(account_id: session[:id])
   @book = Book.where(book_id: b)
   @students = Student.association_join(:books_students).where(book_id: b).by_birth
   @subjects = Subject.association_join(:books_subjects).where(book_id: b).by_name

   erb :'info/book_info'
end



#Page to view individual student info
get('/account/students/:stud_id') do
   s = params['stud_id'].to_i

   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s)

   erb :'info/student_info'
end



#Page to view all activities & books for a given subject
get('/account/subjects/:subj_id') do
   j = params['subj_id'].to_i

   @account = Account.where(account_id: session[:id])
   @subject = Subject.where(subject_id: j, account_id: session[:id])
   @activities = Activity.association_join(:activities_subjects).where(subject_id: j).by_date.reverse
   @students = Student.association_join(:activities_students).by_birth
   @books = Book.association_join(:books_subjects).where(subject_id: j).by_date.reverse
   @book_students = Student.association_join(:books_students)

   erb :'show/subject_filter'
end



#Page to view all activities & books for a given student and a given subject
get('/account/portfolio/:stud_id/:subj_id') do
   s = params['stud_id'].to_i
   j = params['subj_id'].to_i

   @account = Account.where(account_id: session[:id])
   @student = Student.where(student_id: s, account_id: session[:id])
   @subject = Subject.where(subject_id: j)
   @activities = Activity.association_join(:activities_subjects).where(subject_id: j).association_join(:activities_students).where(student_id: s).by_date.reverse
   @books = Book.association_join(:books_subjects).where(subject_id: j).association_join(:books_students).where(student_id: s).by_date.reverse

   erb :'show/student_subjects'
end
