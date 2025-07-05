To properly implement the Apex Mocks Library you need to follow the rules
outlined below:

1) The Apex Mocks Library is ONLY ised for Apex test classes, do
not try to use it for regular Apex classes.

2) When building your Apex test classes using the Apex Mocks Library,
you need to first verify that all classes that are instantiated in the class you are
testing have been instantiated using an Application Apex class (an example of an Application
class you can refernece is in the "Apex Common Library Examples" folder and is named "Example Application"). If the Apex
class you are testing does not instantiate its classes using an Application class, you must
refactor the Apex class you are testing to use an Application class for all the Apex classes it is instantiating. You
can find instructions on how to create an Application Apex class @rules/ApexCommonLibrary/guides/ApexCommonLibraryGuide.md. 

3) When building your Apex test class using the Apex Mocks Library you need to ensure that the Apex class
you are testing is using a selector Apex class to do all of its SOQL queries.