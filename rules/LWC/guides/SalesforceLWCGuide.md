### Lightning Web Component Development Rules   

1. When appropriate, use the @wire decorator to efficiently retrieve data, preferring standard Lightning Data Service.   
2. Implement error handling and display user-friendly error messages using the lwc toast component.   
3. Utilize SLDS (Salesforce Lightning Design System) for consistent styling and layout.   
4. Implement accessibility features, including proper ARIA attributes and keyboard navigation.   
5. Use the lightning-record-edit-form component for handling record creation and updates.   
6. Use the lightning navigation for all navigation in the lightning web component (for example, use lightning navigation when traversing to a web page, a Salesforce record, another lwc, etc).   
7. Generate a jest test for each lightning web component you create.   
8. Opt to make the lightning web component variables configurable by a user whenever appropriate.   
9. Create custom labels to display all text that occurs in inner html for the lightning web component.
10. Prior to making a lightning web component, if I do not explicitly state it, ask me where I would like the component to be allowed to be placed within Salesforce.   
11. Create reusable LWC modules whenever possible to allow for maximum code reuse. An example example of an LWC module can be referenced here @rules/LWC/examples/util_module   
12. Optimize LWC performance wherever possible by leveraging the browser cache and cookies   
13. Optimize all LWC's to be performant and display well on both a desktop and a mobile device    

<!--Need to add examples for mobile, need to figure out how to word lwc modularity right with examples-->
