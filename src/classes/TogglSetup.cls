public with sharing class TogglSetup {
		
	public Toggl__c config {get; set;}

	public TogglSetup() {
		// only doing one token for now, but the list means we can do multiple workspaces later
		for (Toggl__c c : [select Id, Name, API_Token__c, Workspace_ID__c from Toggl__c limit 1]) {
			config = c;
		}
		if (config == null) {
			config = new Toggl__c();
	}
	}

	public void sync() {
		Database.executeBatch(new TogglSync(new Toggl(config.API_Token__c, (Integer)config.Workspace_ID__c)), 10);
	}

	public void save() {
		config.Name = 'default';
		upsert config;
	}
}