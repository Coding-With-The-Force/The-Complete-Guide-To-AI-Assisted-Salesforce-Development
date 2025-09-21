### Your Task (Task Name: Build a user interface that places Salesforce account records as interactive icons on a map) 

1. You will be creating a lightning web component that displays up to 500 Account records on an interactive map.
2. Users should be able to type in an address into a field displayed on the lightning web component and after typing the address into the field and pressing the enter key the map should update with all Salesforce account records within a 50 mile radius of that address.   
3. When you hover over a map marker on the interactive map it should show a description that includes the account name, account annual revenue, account phone number, and the account's address

### Technical Details for context   

1. You will utilize the lightning-map component to display the account records on a map.     
2. You will leverage the account objects ShippingLatitude and ShippingLongitude fields to get the latitude and longitude coordinates to display on the map.
3. You will leverage to SOQL distance function to find all accounts within a 50 mile radius of the address the user entered.     
4. You will create an apex test class for each of the apex classes you write   
5. You will create jest tests for each of the LWC's you create        
