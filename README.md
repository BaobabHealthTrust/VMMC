# VMMC
Setting up this application shouldn't be complicated. By following the instructions below you should be able to setup the application without any difficulties

**Requirements**
1. Ruby version **2.1.2**
2. Rails version **4.2.6**
3. Mysql version **5.5.53**

**How to setup**
###Open your terminal and type the following commands
1. Type *git clone https://github.com/BaobabHealthTrust/VMMC.git*
2. Type *cd VMMC*
3. *cp config/database.yml.example config/database.yml*
4. Open and edit config/database.yml to suit your MySQL settings.
5.   Type *bin/initial_database_setup.sh development mpc*
6. Navigate to public folder of the application
7. *git clone https://github.com/BaobabHealthTrust/touchscreentoolkit.git*
8. Make sure you are in the root of the application
9. *bundle install* This will take some time depending on the speed of your Internet
10. At this time, I assume everything is well. If so then you can start the application by typing *rails s*
11. The application will start on port 3000. If the default port is occupied then you can give -p to specify the port number. For example *rails s -p 3001*

