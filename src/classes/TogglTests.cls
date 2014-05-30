@isTest
private class TogglTests {
    @isTest
    static void itShouldInitialize() {
    	new Toggl('test', 123);
    	new Toggl.TogglUser();
    	new Toggl.TogglProject();
    	new Toggl.TogglClient();
    	new Toggl.TogglDetailedReportResult();
    	new Toggl.TogglTimeEntry();
    }
    @isTest
    static void togglObjectsShouldMakeSobjects() {
    	(new Toggl.TogglUser()).toSObject();
    	(new Toggl.TogglProject()).toSObject();
    	(new Toggl.TogglClient()).toSObject();
    	(new Toggl.TogglTimeEntry()).toSObject();
    }
    @isTest
    static void getMethodsShouldWorkWithEmptyLists() {
    	Toggl t = new Toggl('test', 123);
    	t.getOverride = '[]';
    	System.assert(t.getClients().isEmpty());
    	System.assert(t.getUsers().isEmpty());
    	System.assert(t.getProjects().isEmpty());
    	t.getOverride = '{"data":[]}';
    	System.assert(t.getTimeEntries().data.isEmpty());
    }
}