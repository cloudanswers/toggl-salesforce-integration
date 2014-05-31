@isTest
private class TogglSetupTests {
	
	@isTest static void shouldAutomaticallyCreateNewConfig() {
		TogglSetup controller = new TogglSetup();
		System.assert(controller.config != null);
		controller.save();
		System.assert(controller.config.Id != null);
	}
	
	@isTest static void shouldStartBatch() {
		TogglSetup controller = new TogglSetup();
		controller.sync();
		// TODO assert
	}
}