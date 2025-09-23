/**
 * @author Matt Gerry
 * @date 03/30/2021
 * @description This class is used to create a factory for our application we are working on. Basically
 * it allows you to send in an object type (or something similar) to have different classes returned to you.
 */

public with sharing class Application
{
	//This allows us to create a factory for instantiating service classes. You send it the interface for your service class
	//and it will return the correct service layer class
	//Exmaple initialization: Object objectService = Application.service.newInstance(Task_Service_Interface.class);
	public static final fflib_Application.ServiceFactory service =
			new fflib_Application.ServiceFactory(
					new Map<Type, Type>{
							AccountGeoService.class => AccountGeoService.class}
			);

	//This allows us to create a factory for instantiating selector classes. You send it an object type and it sends
	//you the corresponding selectory layer class.
	//Exmaple initialization: fflib_ISObjectSelector objectSelector = Application.selector.newInstance(objectType);
	public static final fflib_Application.SelectorFactory selector =
			new fflib_Application.SelectorFactory(
					new Map<SObjectType, Type>{
							Account.SObjectType => Account_Selector.class}
			);
}