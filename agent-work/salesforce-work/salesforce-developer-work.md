### Your Task (Task Name: Halo Infinite User Stats Display) 

1. You will be creating an integration with the 343 Industries Halo Infinite API (develop.haloapi.com) to pull data for a specific user and display it in a custom lightning web component.
2. Users should be able to search for a player's user name and then click a "submit" button to retrieve all match statistics for the last 25 matches the user played in.
3. After clicking the submit button the user should then see a data table that shows the statistics from the users last 25 matches, the table should look sleek and modern
4. The user will be able to download an excel file of their statistics to review for themself
5. You will create an apex test class for each of the apex classes you write
6. You will create jest tests for each of the LWC's you create

### Technical Details for context   

1. You will utilize the api's found at develop.haloapi.com. When you are making a callout to these API's you will need to set a header in your Apex code inthe following way to authenticate the callout: 
```
    HttpRequest req = new HttpRequest();
    req.setHeader('Ocp-Apim-Subscription-Key', 'keyvalue');
```
You must pass that Ocp-Apim-Subscription-Key with the value of keyvalue in each transaction or the callouts will fail. I would suggest storing this subscription key in a custom label within Salesforce      
2. The table you display in your lightning web component should look sleek and modern like the one located here: https://colorlib.com/etc/tb/Table_Responsive_v1/index.html      
3. We do not need to store or persist this data in Salesforce, we only need to display it to our users when they request it   
4. Make sure to write your Apex code using the Apex Common Library. A guide to using the Apex Common Library and how I expect you to implement it when writing your code can be found here: @rules/ApexCommonLibrary/guides/ApexCommonLibraryGuide.md    
5. Make sure to write your Apex Tests using the Apex Mocks Library. A guide to using the Apex Mocks Library and how I expect you to implement it when writing your code can be found here: @rules/ApexMocksLibrary/guides/ApexMocksGuide.md   

### Prep Work   
1. Ultrathink about your task prior to starting it and make sure to read through all referenced documentation   
2. Create a README.md file, as you work through this task, output what you have done to accomplish this task, a list of all Salesforce metadata components you have created to complete this task, and a suggested list of todo items to further improve upon the work you have done in the README.md file.    