/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/
import UIKit

@objc protocol DDLFormWidgetDelegate {

	optional func onFormLoaded(elements: [DDLElement])
	optional func onFormLoadError(error: NSError)

	optional func onFormSubmitted(elements: [DDLElement])
	optional func onFormSubmitError(error: NSError)

}

@IBDesignable public class DDLFormWidget: BaseWidget {

	@IBInspectable var structureId: Int = 0
	@IBInspectable var groupId: Int = 0
	@IBInspectable var recordSetId: Int = 0
	@IBInspectable var recordId:Int = 0

	@IBInspectable var repositoryId:Int = 0
	@IBInspectable var folderId:Int = 0
	@IBInspectable var filePrefix = "form-file-"

	@IBInspectable var autoLoad:Bool = true
	@IBInspectable var autoscrollOnValidation:Bool = true
	@IBInspectable var showSubmitButton:Bool = true

	@IBOutlet var delegate: DDLFormWidgetDelegate?

	private var userId:Int = 0

	private var currentOperation:FormOperation = .Idle


	// MARK: BaseWidget METHODS

	override public func becomeFirstResponder() -> Bool {
		return formView().becomeFirstResponder()
	}

	override public func onCreate() {
		formView().showSubmitButton = showSubmitButton
	}

	override public func onShow() {
		if autoLoad && structureId != 0 {
			loadForm()
		}
	}

	override public func onCustomAction(actionName: String?, sender: AnyObject?) {
		if actionName == "submit" {
			submitForm()
		}
	}

	override public func onServerError(error: NSError) {
		switch currentOperation {
			case .Submitting:
				delegate?.onFormSubmitError?(error)
				finishOperationWithMessage("An error happened submitting form")
			case .Loading:
				delegate?.onFormLoadError?(error)
				finishOperationWithMessage("An error happened loading form")
			default: ()
		}

		currentOperation = .Idle
	}

	override public func onServerResult(result: [String:AnyObject]) {
		switch currentOperation {
			case .Submitting:
				if let recordIdValue = result["recordId"]! as? Int {
					recordId = recordIdValue
				}

				finishOperationWithMessage("Form submitted")
			case .Loading:
				onFormLoadResult(result)
			default: ()
		}

		currentOperation = .Idle
	}

	private func onFormLoadResult(result: [String:AnyObject]) {
		if let xml = result["xsd"]! as? String {
			if let userIdValue = result["userId"]! as? Int {
				userId = userIdValue
			}

			let parser = DDLParser(locale:NSLocale.currentLocale())

			parser.xml = xml

			if let elements = parser.parse() {
				formView().rows = elements

				delegate?.onFormLoaded?(elements)

				finishOperationWithMessage("Form loaded")
			}
			else {
				//TODO error
			}
		}
		else {
			//TODO error
		}
	}

	public func loadForm() -> Bool {
		if LiferayContext.instance.currentSession == nil {
			println("ERROR: No session initialized. Can't load form without session")
			return false
		}

		if structureId == 0 {
			println("ERROR: StructureId is empty. Can't load form without it.")
			return false
		}

		startOperationWithMessage("Loading form...", details: "Wait a second...")

		let session = LRSession(session: LiferayContext.instance.currentSession)
		session.callback = self

		let service = LRDDMStructureService_v62(session: session)

		currentOperation = .Loading

		var outError: NSError?

		service.getStructureWithStructureId((structureId as NSNumber).longLongValue, error: &outError)

		if let error = outError {
			onFailure(error)
			return false
		}

		return true
	}

	public func submitForm() -> Bool {
		if LiferayContext.instance.currentSession == nil {
			println("ERROR: No session initialized. Can't submit form without session")
			return false
		}

		if recordSetId == 0 {
			println("ERROR: RecordSetId is empty. Can't submit form without it.")
			return false
		}

		if userId == 0 {
			println("ERROR: UserId is empty. Can't submit form without loading the form before")
			return false
		}

		if !formView().validateForm(autoscroll:autoscrollOnValidation) {
			showHUDWithMessage("Some values are not valid", details: "Please, review your form", secondsToShow: 1.5)
			return false
		}

		currentOperation = .Submitting

		startOperationWithMessage("Submitting form...", details: "Wait a second...")

		let session = LRSession(session: LiferayContext.instance.currentSession)
		session.callback = self

		let service = LRDDLRecordService_v62(session: session)

		var outError: NSError?

		let serviceContextAttributes = [
				"userId":userId,
				"scopeGroupId":groupId != 0 ? groupId : LiferayContext.instance.groupId]

		let serviceContextWrapper = LRJSONObjectWrapper(JSONObject: serviceContextAttributes)

		if recordId == 0 {
			service.addRecordWithGroupId(
				(groupId as NSNumber).longLongValue,
				recordSetId: (recordSetId as NSNumber).longLongValue,
				displayIndex: 0,
				fieldsMap: formView().values,
				serviceContext: serviceContextWrapper,
				error: &outError)
		}
		else {
			service.updateRecordWithRecordId(
				(recordId as NSNumber).longLongValue,
				displayIndex: 0,
				fieldsMap: formView().values,
				mergeFields: true,
				serviceContext: serviceContextWrapper,
				error: &outError)
		}

		if let error = outError {
			onFailure(error)
			return false
		}

		return true
	}

	private func formView() -> DDLFormView {
		return widgetView as DDLFormView
	}

}

private enum FormOperation {
	case Idle
	case Loading
	case Submitting
}
