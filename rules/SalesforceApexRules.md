When writing your Apex classes make sure to follow the rules outlined below:
1) Your Apex class methods should follow the single responsibility principle and do one thing and one thing only.
2) Your Apex class methods should not exceed 25 lines in length. If it becomes longer than 25 lines you need to break it into multiple smaller methods.
3) The Apex code you write needs to utilize the Apex Common Library. Read the "ApexCommonLibraryGuide.md" file in the "rules" directory to determine how to write your Apex classes using the Apex Common Library
4) All Apex code you write needs to have a corresponding Apex test class written for it that has 100% code coverage. Make sure to run the Apex test after you create it to verify that it has 100% coverage.
5) All Apex test classes you write need to use the Apex Mocks Library. 
6) Every Apex method you write needs to be bulkified. It should be able to handled at least 200 records per transaction.
7) If the code you write for your Apex class contains business logic, its class name needs to have the postfix "_Service" appended to it.
8) Make sure that all of the Apex classes you write use the with sharing key words.
9) Use ApexDocs comments to document your Apex classes and its methods.
10) Apex class names should be PascalCase and method and variable names should be camelCase 
11) Implement exception handling for all database transactions in your Apex Class.
12) When you create an Apex class that is a controller for a lightning web component (LWC), there should be NO business logic in the controller. You should make a separate Apex class that is a service class for the business logic and call that service class in your Apex controller. 