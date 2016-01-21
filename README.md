Address Book for iOS Swift
==========================

This repo contains a sample address book application for iOS Swift that demonstrates how to use the DreamFactory REST API. It includes new user registration, user login, and CRUD for related tables.

#Getting DreamFactory on your local machine

To download and install DreamFactory, follow the instructions [here](http://wiki.dreamfactory.com/DreamFactory/Installation). Alternatively, you can create a [free hosted developer account](http://www.dreamfactory.com) at www.dreamfactory.com if you don't want to install DreamFactory locally.

#Configuring your DreamFactory instance to run the app

- Enable [CORS](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) for development purposes.
    - In the admin console, navigate to the Config tab and click on CORS in the left sidebar.
    - Click Add.
    - Set Origin, Paths, and Headers to *.
    - Set Max Age to 0.
    - Allow all HTTP verbs and check the Enabled box.
    - Click update when you are done.
    - More info on setting up CORS is available [here](http://wiki.dreamfactory.com/DreamFactory/Tutorials/Enabling_CORS_Access).

- Create a default role for new users and enable open registration
    - In the admin console, click the Roles tab then click Create in the left sidebar.
    - Enter a name for the role and check the Active box.
    - Go to the Access tab.
    - Add a new entry under Service Access (you can make it more restrictive later).
        - set Service = All
        - set Component = *
        - check all HTTP verbs under Access
        - set Requester = API
    - Click Create Role.
    - Click the Services tab, then edit the user service. Go to Config and enable Allow Open Registration.
    - Set the Open Reg Role Id to the name of the role you just created.
    - Make sure Open Reg Email Service Id is blank, so that new users can register without email confirmation.
    - Save changes.

- Import the package file for the app.
    - From the Apps tab in the admin console, click Import and click 'Address Book for iOS Swift' in the list of sample apps. The Address Book package contains the application description, schemas, and sample data.
    - Leave storage service and folder blank. This is a native iOS app so it requires no file storage on the server.
    - Click the Import button. If successful, your app will appear on the Apps tab. You may have to refresh the page to see your new app in the list.
    
- Make sure you have a SQL database service named 'db'. Depending on how you installed DreamFactory you may or may not have a 'db' service already available on your instance. You can add one by going to the Services tab in the admin console and creating a new SQL service. Make sure you set the name to 'db'.

#Running the Address Book app

Almost there! Clone this repo to your local machine then open and run the project with Xcode.

Before running the project you need to edit API_KEY in the file Network/RESTEngine.swift to match the key for your new app. This key can be found by selecting your app from the list on the Apps tab in the admin console.

The default instance URL is localhost:8080. If your instance is not at that path, you can change the default path in Network/RESTEngine.swift.

When the app starts up you can register a new user, or log in as an existing user. Currently the app does not support registering and logging in admin users.

#Additional Resources

More detailed information on the DreamFactory REST API is available [here](http://wiki.dreamfactory.com/DreamFactory/API).

The live API documentation included in the admin console is a great way to learn how the DreamFactory REST API works.
